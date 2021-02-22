#!/usr/bin/env bash

. $(dirname $0)/demo.conf

if [[ $EUID -ne 0 ]]
then
    echo
    echo "*** MUST RUN AS root ***"
    echo
    exit 1
fi

# install image builder and other necessary packages
yum -y install osbuild-composer composer-cli cockpit-composer \
    bash-completion jq

# enable image builder to start after reboot
systemctl enable --now cockpit.socket osbuild-composer.socket

# add user to weldr group so they don't need to be root to run image builder
[[ ! -z "$SUDO_USER" ]] && usermod -aG weldr $SUDO_USER

firewall-cmd --permanent --add-port=8000/tcp
firewall-cmd --reload

# prep the edge.ks file
cat edge.ks.orig | \
    sed "s/__HOST_IP__/$HOST_IP/g" > edge.ks

