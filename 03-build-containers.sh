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
# Install needed executables using the recommended module
#
yum -y module install container-tools

#
# Setup for a local insecure registry
#
firewall-cmd --permanent --add-port=5000/tcp
firewall-cmd --reload

mkdir -p /var/lib/registry
sed -i.bak '/\[registries.insecure\]/!b;n;cdummy' \
    /etc/containers/registries.conf
sed -i "s/dummy/registries = ['"$HOST_IP":5000']/g" \
    /etc/containers/registries.conf

#
# Create systemd unit files for both service and socket
#
CTR_ID=$(podman run --privileged -d --name registry -p 5000:5000 -v /var/lib/registry:/var/lib/registry:Z --restart=always docker.io/library/registry:2)
podman generate systemd --new --files --name $CTR_ID
podman stop --all
podman rm -f --all
podman rmi -f --all

#
# Enable registry service
#
cp container-registry.service /etc/systemd/system
restorecon -vFr /etc/systemd/system
systemctl enable --now container-registry.service
systemctl daemon-reload

#
# Create containerized httpd application version 1
#
CTR_ID=$(buildah from registry.access.redhat.com/ubi8/ubi:latest)
buildah run $CTR_ID -- yum -y install httpd
echo 'Welcome to RHEL for Edge!' > index.html
buildah copy $CTR_ID index.html /var/www/html/index.html
buildah config --cmd "/usr/sbin/httpd -D FOREGROUND" $CTR_ID
buildah config --port 80 $CTR_ID
buildah commit $CTR_ID $HOST_IP:5000/httpd:v1

podman push $HOST_IP:5000/httpd:v1

#
# Tag the image with prod in the local insecure registry
#
podman tag $HOST_IP:5000/httpd:v1 $HOST_IP:5000/httpd:prod
podman push $HOST_IP:5000/httpd:prod

#
# Create containerized httpd application version 2
#
CTR_ID=$(buildah from $HOST_IP:5000/httpd:v1)
echo "Podman auto-update is awesome!" >> index.html
buildah copy $CTR_ID index.html /var/www/html/index.html
buildah commit $CTR_ID $HOST_IP:5000/httpd:v2

podman push $HOST_IP:5000/httpd:v2

podman images

