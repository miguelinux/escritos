#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
#
# SPDX-License-Identifier: GPL-3.0-or-later

source /usr/lib/os-release

if [ $UID -ne 0 ]
then
    echo "Please run with \"root\" or \"sudo $0\""
    exit 1
fi

if [ "$NAME" = "Debian GNU/Linux" ]
then
    if [ -d /etc/apt/sources.list.d ]
    then
        echo "deb http://deb.debian.org/debian stable-backports main non-free-firmware" > /etc/apt/sources.list.d/stable-backports.list
        apt-get update
    fi
fi
echo Examples:
echo sudo apt-get -t stable-backports install linux-image-amd64
echo sudo apt-get install -t stable-backports qemu-system-x86
