#!/usr/bin/env bash

. $(dirname $0)/demo.conf

virt-install \
    --name edge-device \
    --memory 8192 \
    --vcpus 4 \
    --location rhel-8.3-x86_64-boot.iso \
    --extra-args="inst.ks=http://${HOST_IP}:8000/edge.ks ip.method=dhcp console=ttyS0" \
    --os-variant=rhel8.3 \
    --disk size=64 \
    --graphics none

