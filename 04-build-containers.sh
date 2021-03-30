#!/usr/bin/env bash

. $(dirname $0)/demo.conf

#
# We need to add the $HOSTIP to the network interface to push the
# images to our server. This same address will be available when the
# edge guest is running later with SLiRP networking.
#
ETHDEV=$(ip route get 8.8.8.8 | sed 's/.*dev //g' | awk '{print $1;exit}')
sudo nmcli con mod $ETHDEV +ipv4.addresses $HOSTIP/24
sudo nmcli con down $ETHDEV
sudo nmcli con up $ETHDEV

#
# Create containerized httpd application version 1
#
CTR_ID=$(buildah from registry.access.redhat.com/ubi8/ubi:latest)
buildah run $CTR_ID -- yum -y install httpd
echo 'Welcome to RHEL for Edge!' > index.html
buildah copy $CTR_ID index.html /var/www/html/index.html
buildah config --cmd "/usr/sbin/httpd -D FOREGROUND" $CTR_ID
buildah config --port 80 $CTR_ID
buildah commit $CTR_ID $HOSTIP:5000/httpd:v1

podman push $HOSTIP:5000/httpd:v1

#
# Tag the image as "prod" in the local insecure registry
#
podman tag $HOSTIP:5000/httpd:v1 $HOSTIP:5000/httpd:prod
podman push $HOSTIP:5000/httpd:prod

#
# Create containerized httpd application version 2
#
CTR_ID=$(buildah from $HOSTIP:5000/httpd:v1)
echo "Podman auto-update is awesome!" >> index.html
buildah copy $CTR_ID index.html /var/www/html/index.html
buildah commit $CTR_ID $HOSTIP:5000/httpd:v2

podman push $HOSTIP:5000/httpd:v2

