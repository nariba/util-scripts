#!/bin/sh

for vmname in `sudo virsh list --state-shutoff --name`
do
    echo $vmname 'compress start'
    # sudo virsh domblklist $vmname | grep qcow2 の結果が空の場合にはスキップ
    if [ -z "`sudo virsh domblklist $vmname | grep qcow2`" ];
    then
        echo $vmname 'is running so skip'
        continue
    fi
    imagefile=`sudo virsh domblklist $vmname | grep qcow2 | awk '{print $2}'`
    # qcow2ファイルがない場合にはスキップ
    if [ ! -f $imagefile ];
    then
        echo $vmname 'image file not found so skip'
        continue
    fi
    tmp=${imagefile%.*}
    sudo qemu-img convert -p -c -f qcow2 -O qcow2 ${tmp}{,.compressed}.qcow2
    sudo chown qemu:libvirt_shared ${tmp}.compressed.qcow2
    sudo mv $tmp.compressed.qcow2 $tmp.qcow2

    echo $vmname 'compress finish'
done