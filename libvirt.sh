#!/bin/sh

# Allow libvirt group users to manipulate 
# virtual machines with the virsh command without sudo.
# Place it under /etc/profile.d/ or similar so that 
# environment variables are set when the shell is started. 

export LIBVIRT_DEFAULT_URI="qemu:///system"

