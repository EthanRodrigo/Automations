#!/bin/bash

devices="/dev/$(lsblk -db | awk '/ 8:/' | awk '{print $1" "$4}' | sort -k 2 | tail -n1 | awk '{print $1}')" # default is the largest drive
let "percentage = (($(lsblk -db | awk '/ 8:/' | awk '{print $1" "$4}' | sort -k 2 | tail -n1 | awk '{print $2}') * 10) / 100)" # 10 percent of the device
rootSize=$(echo $(awk -v n="$asd" 'BEGIN{printf "%.1f", n/1073741824}'))
vgroupName="volgroup0" # the default volume group name
partitions=""

if ! ARGUMENTS=$(getopt -a -n setuplvm -o hr:v:d: --l help,root-size:,vgroup-name:,devices: -- "$@") # storing arguments in an array
then
	exit 1
fi
printHelp(){
	# help function
	echo "Usage: setuplvm
or : setuplvm [OPTIONS]

-r size-of-root, --root-size size-of-root
		Change the size of the root logical volume. Default is 10% size of the device.
-v virtual-group-name, --vgroup-name virtual-group-name
		Change the label of the virtual group. Default is \`vgroup0\`.
-d drive/s, --devices drive/s
		Change the default drive. Default is the largest device. You can add a list of array inside \"\", like \`-d \"/dev/sda /dev/sdb\"\`.
-h help, --help
		Prints this
	"
}
getArg(){
	# argument extractor
	eval set -- "$ARGUMENTS"
	while [ $# -gt 0 ]
	do
		case $1 in
			-r | --root-size) rootSize="$2"; shift;;
			-v | --vgroup-name) vgroupName="$2"; shift;;
			-d | --devices) devices=""; devices+="$2"; shift;;
			-h | --help) printHelp; exit;; 
			-- ) shift; break;;
			*) echo Unexpected arg;;
		esac
		shift
	done
}
partition(){
# partitioning
fdisk $1 <<EOF
d
n
p



t
8e
p

w
EOF

# creating an array of partitions
for dev in $devices
do
	device=$(cut -d '/' -f 3 <<< "$dev")
	part=$(echo $(grep "$device[0-100]" /proc/partitions | awk '{print $4}'))
	partitions+="/dev/$part"
done
}
LvmSetup(){
	# the real lvm setup :xd
	for part in $partitions # pvcreate needs one by one
	do
		pvcreate --dataalignment 1m $part
	done
	vgcreate $vgroupName $partitions
	lvcreate -L $rootSize"G" $vgroupName -n root # the root named root, what else you need, huh?
	lvcreate -l 100%FREE $vgroupName -n home # and home is home

	# activating volume groups
	modprobe dm_mod
	vgchange -ay
}
laterSetup(){
	# formatting and mounting
	mkfs.ext4 "/dev/$vgroupName/root"
	mount "/dev/$vgroupName/root" /mnt

	mkfs.ext4 "/dev/$vgroupName/home"
	mkdir /mnt/home
	mount "/dev/$vgroupName/home" /mnt/home

	# settingup fstab
	mkdir /mnt/etc
	genfstab -U -p /mnt >> /mnt/etc/fstab
}
checkForErrors(){
	# checks out whether the vgroup has created or not
	if [[ $(vgs | awk '{print $1}') != *$vgroupName*  ]]; then 
		echo "Virtual group can't br created"
	# checks for root and home logical volumes
	elif [[ $(lvs | awk '{print $1}') != *"root"* ]]; then 
		echo "Logical volume root haven't been created"
	elif [[ $(lvs | awk '{print $1}') != *"home"* ]]; then
		echo "Logical volume home haven't been created"
	# checks fot root and home in fstab
	elif [ $(echo $(cat /mnt/etc/fstab | awk '{print $2}' | grep 'root\|home' | wc -l)) != 3 ]; then 
		echo "Error in fstab"
	else 
		echo "Fret not! No errors"
	fi
}
main(){
	getArg

	for dev in $devices
	do
		partition $dev
	done

	LvmSetup
	laterSetup
	checkForErrors
}
main
