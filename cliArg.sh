#!/bin/bash

devices="/dev/$(lsblk -db | awk '/ 8:/' | awk '{print $1" "$4}' | sort -k 2 | tail -n1 | awk '{print $1}')" # default is the largest drive
let "rootSize = (($(lsblk -db | awk '/ 8:/' | awk '{print $1" "$4}' | sort -k 2 | tail -n1 | awk '{print $2}') * 10) / 100) / 1073741824" # default root size is the 10% of the actual size
vgroupName="volgroup0" # the default volume group name

if ! ARGUMENTS=$(getopt -a -n setuplvm -o r:v:d: --l root-size:,vgroup-name:,devices: -- "$@") # storing arguments in an array
then
	exit 1
fi

getArg(){
	eval set -- "$ARGUMENTS"
	while [ $# -gt 0 ]
	do
		case $1 in
			-r | --root-size) rootSize="$2"; shift;;
			-v | --vgroup-name) vgroupName="$2"; shift;;
			-d | --devices) devices=""; devices+="$2"; shift;;
			-- ) shift; break;;
			*) echo Unexpected arg;;
		esac
		shift
	done
}

getArg

echo $rootSize
echo $vgroupName

for dev in $devices
do
	echo $dev
done

partitions=""
for dev in $devices
do
	device=$(cut -d '/' -f 3 <<< "$dev")
	part=$(echo $(grep "$device[0-100]" /proc/partitions | awk '{print $4}'))
	partitions+="/dev/$part"
done

echo $partitions
