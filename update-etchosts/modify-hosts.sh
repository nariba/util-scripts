#!/bin/sh -e

tmp=`grep -n "# If you want to update manually, put it above this comment line." /etc/hosts | awk -F: '{print($1)}'`

line=`bc <<<"$tmp+1"`

sed -i "$line,\$d" /etc/hosts

virsh net-dhcp-leases default | awk '{print($5" "$6)}' | sed -e 's/\/24//g' -e 's/-guest//g' | tail -n+3 | head -n-1 >> /etc/hosts
