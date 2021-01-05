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

OS=centos8  # look for it using "osinfo-query os"

NETWORK=default
CONNECT=qemu:///system
VM_DISK=/path/to/disk
VM_ISO=/path/to/iso

if test -f ${HOME}/.config/qemu-scripts/install.conf
then
    source ${HOME}/.config/qemu-scripts/install.conf
fi

#    --dry-run          \
#    --print-xml        \

    # --graphics spice,port=${SPICE_PORT} \

#sudo \
virt-install \
    --connect ${CONNECT} \
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
    --graphics spice \
    --video qxl        \
    --channel spicevmc,target_type=virtio  \
    --network network=${NETWORK},model=virtio \
    --cdrom ${VM_ISO}      \
    --disk path=${VM_DISK},bus=virtio  \
    --boot uefi
