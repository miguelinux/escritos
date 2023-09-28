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
        echo "deb http://deb.debian.org/debian unstable main" > /etc/apt/sources.list.d/unstable.list
        apt-get update
        apt-get -t unstable -y install linux-image-amd64
        rm /etc/apt/sources.list.d/unstable.list
        apt-get update
    fi
fi
