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

case $ID in
    debian|ubuntu)
        apt-get -y update
        apt-get -y install git stow tmux vim rsync connect-proxy curl xmlto
        apt-get -y install build-essential fakeroot devscripts unifdef libncurses-dev
        apt-get -y install python3-dacite guilt
        apt-get -y build-dep linux
    ;;
esac
