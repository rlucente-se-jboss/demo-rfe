#!/usr/bin/env bash

. $(dirname $0)/demo.conf

#
# Create an empty disk for install
#
rm -f edge-disk.qcow2
qemu-img create -f qcow2 edge-disk.qcow2 $HDD_SIZE

#
# Loop mount ISO to get the kernel and ramdisk
#
sudo mkdir -p /media/cdrom
sudo mount $ISO_PATH /media/cdrom -o loop

#
# Install the edge device using Direct Linux Boot so we can append
# arguments to the kernel command line. QEMU is running in user space
# with SLiRP networking. All output is redirected to the user terminal.
#
qemu-system-x86_64 \
    -kernel /media/cdrom/isolinux/vmlinuz \
    -initrd /media/cdrom/isolinux/initrd.img \
    -append "inst.text inst.ks=http://$HOSTIP:8000/edge.ks console=ttyS0 ipv6.disable=1" \
    -serial mon:stdio \
    -nographic \
    -m $MEM_SIZE \
    -device virtio-net-pci,netdev=n0 \
    -netdev user,id=n0,net=$VM_NET \
    -drive file=edge-disk.qcow2 \
    -cdrom $ISO_PATH

sudo umount /media/cdrom

