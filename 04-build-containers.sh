#!/usr/bin/env bash

. $(dirname $0)/demo.conf

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

