#!/bin/bash

tmp=$(echo $(lsblk -d | awk '/ 8:/' | awk '{print $1" "$4}' | sort -k 2 | tail -n1) | cut -d G -f1) # no harcoding :-)
devices="/dev/$(echo $tmp | awk '{print $1}')"
vgroupName="volgroup0" # the default volume group name
partitions=""
filesystem="ext4"
home=''

if [ $(echo $tmp | awk '{print $2}') -gt 10 ]; then
	home='Y'
else
	home='N'
fi

if ! ARGUMENTS=$(getopt -a -n setuplvm -o hr:v:f:d:u: --l help,root-size:,vgroup-name:,filesystem:,devices:,user-home: -- "$@") # storing arguments in an array
then
	exit 1
fi
printHelp(){
	# help function
	echo "Usage: setuplvm
or : setuplvm [OPTIONS]

-r size-of-root, --root-size size-of-root
		Change the size of the root logical volume. Default is 10% size of the device.
		The size should be \`G\` for Gigabyte or \`M\` for Megabyte.
		ex: -r 10G
-v virtual-group-name, --vgroup-name virtual-group-name
		Change the label of the virtual group. Default is \`vgroup0\`.
-d drive/s, --devices drive/s
		Change the default drive. Default is \`/dev/sda\`. You can add a list of array inside \"\", like \`-d \"/dev/sda /dev/sdb\"\`.
-f file-system, --filesystem file-system
		Change the file system. Default file system is ext4
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
			-d | --devices) unset devices; devices+="$2"; shift;;
			-f | --filesystem) filesystem="$2"; shift;;
			-u | --user-home) 
				home="$2";
				home=$(echo ${home^^});
				shift;;
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
}
LvmSetup(){
	# the real lvm setup :xd
	for part in $partitions # pvcreate needs one by one
	do
		pvcreate --dataalignment 1m $part
	done
	vgcreate $vgroupName $partitions

	vgSize=$(echo $(vgs | awk '{print $6}' | awk 'NR==2' | cut -d . -f1)) # virtual group size

	if [ $vgSize -gt 10 ]; then # if vgroup's size is greater than 10
		home='Y' # there would be a home
		rootSize=$(echo $(bc -l <<< "scale=1; $vgSize * 10 / 100"))"G"
	fi

	if [[ $home =~ 'Y' ]];then # if there's home also
		lvcreate -L $rootSize $vgroupName -n root # the root named root, what else you need, huh?
		lvcreate -l 100%FREE $vgroupName -n home # and home is home
	else # or else use the whole drive only for root
		lvcreate -l 100%FREE $vgroupName -n root
	fi

	# activating volume groups
	modprobe dm_mod
	vgchange -ay
}
laterSetup(){
	# formatting and mounting
	mkfs.$filesystem "/dev/$vgroupName/root"
	mount "/dev/$vgroupName/root" /mnt


	if [[ $(lvs | awk '{print $1}') == *"home"* ]]; then
		mkfs.$filesystem "/dev/$vgroupName/home"
		mkdir /mnt/home
		mount "/dev/$vgroupName/home" /mnt/home
	fi

	# settingup fstab
	mkdir /mnt/etc
	genfstab -U -p /mnt >> /mnt/etc/fstab
}
checkForErrors(){
	# checks out whether the vgroup has created or not
	if [[ $(vgs | awk '{print $1}') != *$vgroupName*  ]]; then 
		echo "Virtual group can't be created"
	# checks for root and home logical volumes
	elif [[ $(lvs | awk '{print $1}') != *"root"* ]]; then 
		echo "Logical volume root haven't been created"
	elif [[ $(lvs | awk '{print $1}') != *"home"* ]]; then
		echo "Logical volume home haven't been created"
		echo "Fret not! No errors"
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

	# creating an array of partitions
	for dev in $devices
	do
		device=$(cut -d '/' -f 3 <<< "$dev")
		partitions+="/dev/$(echo $(grep "$device[0-100]" /proc/partitions | awk '{print $4}')) "
	done

	LvmSetup
	laterSetup
	checkForErrors
}
main
