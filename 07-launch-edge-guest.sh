#!/usr/bin/env bash

. $(dirname $0)/demo.conf

#
# Only launch QEMU if disk image exists, i.e. the install was
# previously run
#
if [ ! -f edge-disk.qcow2 ]
then
    echo "*** Missing edge disk ***"
    echo "Please install the QEMU edge system first"
    exit 1
fi

#
# Launch the existing edge device
#
qemu-system-x86_64 \
    -serial mon:stdio \
    -nographic \
    -m $MEM_SIZE \
    -device virtio-net-pci,netdev=n0 \
    -netdev user,id=n0,net=$VM_NET \
    -drive file=edge-disk.qcow2

