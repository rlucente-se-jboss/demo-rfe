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
# Enable codeready since EPEL needs it
#
subscription-manager repos \
    --enable=codeready-builder-for-rhel-8-x86_64-rpms

#
# Install EPEL but disable it's repos
#
dnf -y install dnf-utils \
    https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
dnf config-manager --disable epel epel-modular

#
# Temporarily enable EPEL repos to install full QEMU package
#
dnf -y install --enablerepo=epel $QEMU_RPM

