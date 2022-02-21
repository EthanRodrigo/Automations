#!/bin/bash

# Setting up the sda with fdisk
partition(){
device=""
if [ "$#" -ne 1]; then  # if no arguments were provided
	device=$(lsblk -db | awk '/ 8:/' | awk '{print $1" "$4}' | sort -k 2 | head -n1 | awk '{print $1}') # then use the largest drive
fi

fdisk /dev/$device <<EOF
d
n
p



t
8e
p
EOF
}

# paritition $1
