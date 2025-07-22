#!/bin/sh -e

for vmname in `virsh list --state-shutoff --name`
do
    if ! virsh list --state-shutoff --name | grep -qx $vmname;
    then
        echo $vmname 'is running, skip'
        continue
    fi
    echo $vmname 'compress start'
    # sudo virsh domblklist $vmname | grep qcow2 の結果が空の場合にはスキップ
    if [ -z "`virsh domblklist $vmname | grep qcow2`" ];
    then
        echo $vmname 'is running so skip'
        continue
    fi

    for imagefile in `virsh domblklist $vmname | grep qcow2 | awk '{print $2}'`
    do
        # qcow2ファイルがない場合にはスキップ
        if [ ! -f $imagefile ];
        then
            echo $vmname 'image file not found so skip'
            continue
        fi
        echo $vmname 'imagefile: ' $imagefile 'compress start'
        tmp=${imagefile%.*}
        sudo qemu-img convert -p -c -f qcow2 -O qcow2 ${tmp}{,.compressed}.qcow2
        sudo chown qemu:libvirt_shared ${tmp}.compressed.qcow2
        sudo mv $tmp.compressed.qcow2 $tmp.qcow2
        echo $vmname 'imagefile: ' $imagefile 'compress finish'
    done

    echo $vmname 'compress finish'
done