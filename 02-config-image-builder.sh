#!/usr/bin/env bash

. $(dirname $0)/demo.conf

if [[ $EUID -ne 0 ]]
then
    echo
    echo "*** MUST RUN AS root ***"
    echo
    exit 1
fi

# install RHEL 8 virtualization module
yum -y module install virt

# install image builder and other necessary packages
yum -y install osbuild-composer composer-cli cockpit-composer \
    bash-completion jq virt-install virt-viewer golang

# enable libvirtd
systemctl enable --now libvirtd

# enable image builder to start after reboot
systemctl enable --now cockpit.socket osbuild-composer.socket

# add user to weldr group so they don't need to be root to run image builder
[[ ! -z "$SUDO_USER" ]] && usermod -aG weldr $SUDO_USER

firewall-cmd --permanent --add-port=8000/tcp
firewall-cmd --reload

# prep the edge.ks file
envsubst < edge.ks.orig > edge.ks

echo "Verify that system is prepared to be a virtualization host"
virt-host-validate

