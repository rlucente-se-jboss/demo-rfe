#!/usr/bin/env bash

. $(dirname $0)/demo.conf

if [[ $EUID -ne 0 ]]
then
    echo
    echo "*** MUST RUN AS root ***"
    echo
    exit 1
fi

#
# Install using the recommended module
#
dnf -y module install container-tools

#
# Setup for a local insecure registry
#
firewall-cmd --permanent --add-port=5000/tcp
firewall-cmd --reload

mkdir -p /var/lib/registry
sed -i.bak '/\[registries.insecure\]/!b;n;cdummy' \
    /etc/containers/registries.conf
sed -i "s/dummy/registries = ['"$HOSTIP":5000']/g" \
    /etc/containers/registries.conf

#
# Create systemd unit files for registry service
#
CTR_ID=$(podman run --privileged -d --name registry -p 5000:5000 -v /var/lib/registry:/var/lib/registry:Z --restart=always docker.io/library/registry:2)
podman generate systemd --new --files --name $CTR_ID

#
# Clean up running containers
#
podman stop --all
podman rm -f --all

#
# Enable registry service
#
cp container-registry.service /etc/systemd/system
restorecon -vFr /etc/systemd/system
systemctl enable --now container-registry.service
systemctl daemon-reload

