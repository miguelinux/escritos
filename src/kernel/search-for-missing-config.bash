#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
#
# SPDX-License-Identifier: GPL-3.0-or-later


# Look for missing config from base_config to check_config
base_config=$1
check_config=$2

while read -r line; do
    if [ "#" = ${line:0} ]
        continue
    fi
    echo $line
done < $1

