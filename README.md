# Arch

## setuplvm
This is a small script to automate the process of setting up lvm. You can get more information on how to use this with -h option.

####	options
-h --> Help
-r --> Root size, default is 10% of the drive.
-v --> Volume group name, default is `vgroup0`
-d --> A device or an array of devices, default is the largest device. Please be kind enough to put the device names within "", like `-d "/dev/sda /dev/sdb"`. 
