#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
#
# SPDX-License-Identifier: GPL-3.0-or-later
#

source /usr/lib/os-release

if [ $UID -ne 0 ]
then
    echo "Please run with \"root\" or \"sudo $0\""
    exit 1
fi

if [ ! -d /home/alumno ]
then
    useradd \
	--uid 1900 \
	--shell /usr/bin/bash \
	--create-home \
	--home-dir /home/alumno \
        --groups users  \
	--comment "Alumno" \
	alumno
fi

#	--groups cdrom,dip,plugdev,lpadmin,lxd,familia,sambashare  \

if [ -d /etc/sudoers.d ]
then
    echo "alumno ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/015_alumno-nopasswd
fi

if [ -d /home/alumno -a ! -d /home/alumno/.local/git/dotfiles ]
then
    mkdir -p /home/alumno/.local/git
    git -C /home/alumno/.local/git clone https://github.com/miguelinux/dotfiles.git
    chown -R alumno:alumno /home/alumno
fi

