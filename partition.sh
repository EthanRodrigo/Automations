#!/bin/bash

# Setting up the sda with fdisk
partition(){
fdisk /dev/sda <<EOF
d
n
p



t
8e
p
EOF
}
