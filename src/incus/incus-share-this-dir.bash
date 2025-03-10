#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
#
# SPDX-License-Identifier: GPL-3.0-or-later

instance_name=$1
device_name=$2
path_in_instance=$3
path_on_host=$(realpath $PWD)

if [ -z "${instance_name}" ]
then
    >&2 echo "Falta nombre del contenedor"
    >&2 echo ""
    >&2 echo "$0 <instance_name> <device_name> <path_in_instance>"
    exit 1
fi

if [ -z "${device_name}" ]
then
    >&2 echo "Falta nombre/variable del dispositivo"
    >&2 echo ""
    >&2 echo "$0 <instance_name> <device_name> <path_in_instance>"
    exit 1
fi

if [ -z "${path_in_instance}" ]
then
    >&2 echo "Falta ruta interna del directorio"
    >&2 echo ""
    >&2 echo "$0 <instance_name> <device_name> <path_in_instance>"
    exit 1
fi


incus config device add ${instance_name} ${device_name} disk \
    source=${path_on_host} \
    path=${path_in_instance} \
    shift=true
