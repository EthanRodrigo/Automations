# Arch

## setupLVM

This is a small script to automate the process of setting up lvm. You can get more information on how to use this with -h option.

options

-r, --root-size --> Specify the root size. Default is 10% size of the device.
		The size should be \`G\` for Gigabyte or \`M\` for Megabyte.
		ex: -r 10G

-v, --vgroup-name --> Change the label of the virtual group. Default is \`vgroup0\`.

-d, --devices --> Change the default drive. Default is \`/dev/sda\`. 
		You can add a list of array inside \"\".
		ex; \`-d \"/dev/sda /dev/sdb\"\`.

-f, --filesystem --> Change the file system. Default file system is ext4

-u, --user-home --> Specify whether you need a home partition or not. Default is 'Y' when there's space more than 10Gigs

-e, --efi-dev	--> The drive where you need to have a uefi partition.

-h, --help --> Prints this
