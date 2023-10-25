#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
#
# SPDX-License-Identifier: GPL-3.0-or-later

EXTRA_CMD=""

if [ -f $HOME/.aws/cmd/$1 ]
then
    EXTRA_CMD=$(< $HOME/.aws/cmd/$1)
fi

aws ec2 start-instances ${EXTRA_CMD}
