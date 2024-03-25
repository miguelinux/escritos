#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
#
# SPDX-License-Identifier: GPL-3.0-or-later

test -e /etc/os-release && os_release='/etc/os-release' || os_release='/usr/lib/os-release'
source "${os_release}"

if [ $UID -ne 0 ]
then
    echo "Please run with \"root\" or \"sudo $0\""
    exit 1
fi

SSHD_FILE=/etc/ssh/sshd_config

if [ -f ${SSHD_FILE} ]
then
    sed -i "/^PermitRootLogin/c PermitRootLogin yes" ${SSHD_FILE}
    sed -i "/#PermitRootLogin/c PermitRootLogin yes" ${SSHD_FILE}
fi

