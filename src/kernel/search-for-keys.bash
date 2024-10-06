#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
#
# SPDX-License-Identifier: GPL-3.0-or-later

# Use base to look for the value in check_config
base_config=$1
shift
check_config=$*

echo 

while read -r line; do
    #if [ "#" = "${line:0:1}" ]
    #if [ -z "${line}" ]
    c="CONFIG_${line}"

    echo -n "${line}"
    for f in $check_config 
    do 
        k=$(grep "${c}=" ${f})
        if [ -n "$k" ]
        then
            v=${k#*=}
        else
            k=$(grep "# ${c} is not set" ${f})
            if [ -n "$k" ]
            then
                v="n"
            else
                v="unknown"
            fi
        fi
        echo -n ",${v}"
    done
    echo

done < $base_config

