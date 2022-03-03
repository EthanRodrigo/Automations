#!/bin/bash

devices="/dev/$(lsblk -db | awk '/ 8:/' | awk '{print $1" "$4}' | sort -k 2 | tail -n1 | awk '{print $1}')" # default is the largest drive
let "rootSize = (($(lsblk -db | awk '/ 8:/' | awk '{print $1" "$4}' | sort -k 2 | tail -n1 | awk '{print $2}') * 10) / 100) / 1073741824" # default root size is the 10% of the actual size
vgroupName="volgroup0" # the default volume group name

if ! ARGUMENTS=$(getopt -a -o hr:v:d: --l --help,root-size:,vgroup-name:,devices: -- "$@") # storing arguments in an array
then
	exit 1
fi
printHelp(){
	echo -e "Usage: setuplvm
or : setuplvm [OPTIONS]

-r size-of-root, --root-size size-of-root
		Change the size of the root logical volume. Default is 10% size of the device.
-v virtual-group-name, --vgroup-name virtual-group-name
		Change the label of the virtual group. Default is \`vgroup0\`.
-d drive/s, --devices drive/s
		Change the default drive. Default is \`/dev/sda\`. You can add a list of array inside \"\", like \` -d \"/dev/sda /dev/sdb\" \`.
-h help, --help
		Prints this
	"
}
getArg(){
	eval set -- "$ARGUMENTS"
	while [ $# -gt 0 ]
	do
		case $1 in
			-r | --root-size) rootSize="$2"; shift;;
			-v | --vgroup-name) vgroupName="$2"; shift;;
			-d | --devices) devices=""; devices+="$2"; shift;;
			-h | --help) printHelp; exit;;
			(--) shift; break;;
			(-*) echo "$0: error - unrecognized option $1" 1>&2; exit 1;;
		    (*) break;;
		esac
		shift
	done
}
#printHelp
getArg

echo $rootSize
echo $vgroupName

for dev in $devices
do
	echo $dev
done
if [[ $(lvs | awk '{print $1}') != *"root"* &&  $(lvs | awk '{print $1}') != *"home"* ]]; then 
	echo "It's fucking here"
else
	echo "Shit"
fi
: '
partitions=""
for dev in $devices
do
	device=$(cut -d '/' -f 3 <<< "$dev")
	part=$(echo $(grep "$device[0-100]" /proc/partitions | awk '{print $4}'))
	partitions+="/dev/$part"
done

echo $partitions
'
