#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
#
# SPDX-License-Identifier: GPL-3.0-or-later

NAME=CentOSvm1
DESCRIPTION="CentOS 8 VM 1"
VCPUS="sockets=1,cores=4,threads=2"  # 1x4x2
# vCPUS x 2048 # hay un dicho que 2GiB por CPU
MB=16384
SPICE_PORT=5924
VM_DISK=/dev/data/centosvm1
VM_ISO=/srv/ISOs/CentOS-8.2.2004-x86_64-boot.iso
OS=centos8  # look for it using "osinfo-query os"

sudo \
virt-install \
    --dry-run          \
    --print-xml        \
    --connect qemu:///system \
    --name ${NAME}     \
    --metadata description="${DESCRIPTION}" \
    --autostart        \
    --vcpus ${VCPUS}   \
    --cpu host         \
    --memory ${MB}     \
    --virt-type kvm    \
    --os-variant ${OS} \
    --clock offset=localtime \
    --pm suspend_to_disk=off,suspend_to_mem=off \
    --graphics spice,port=${SPICE_PORT} \
    --video qxl        \
    --channel spicevmc,target_type=virtio  \
    --network network=default,model=virtio \
    --cdrom ${VM_ISO}      \
    --disk path=${VM_DISK},bus=virtio
