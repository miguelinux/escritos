#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
#
# SPDX-License-Identifier: GPL-3.0-or-later

ISO_DISTRO=9-stream
ISO_STORAGE=.

# ISO_DISTRO=centos/8-stream
# ISO_STORAGE=.

SILENT="--silent"
QUIET="--quiet"

SHOW_HELP=0

### Get user config
if test -f $HOME/.config/qemu-script/get-iso.conf
then
    source $HOME/.config/qemu-script/get-iso.conf
fi

show_help() {
    echo "Usage: $0 [parameters]"
    echo ""
    echo "PARAMETERS"
    echo ""
    echo "-v, --verbose      Shows commands output"
    echo "-d, --debug        Set debug mode in bash, i.e. set -x"
    echo "-e, --error        Set error mode in bash, i.e. set -e"
    echo "--distro DISTRO    Set the url DISTRO name part, i.e. 9-stream"
    echo "-s, --storage PATH Set the PATH to save ISO file"
    echo "-h, --help         Shows this help"
    echo ""
    echo "Current setup is:"
    echo "  Distro  = ${ISO_DISTRO}"
    echo "  Storage = ${ISO_STORAGE}"
    echo ""
    echo -n "config file at: $HOME/.config/qemu-script/get-iso.conf"
    if test -f $HOME/.config/qemu-script/get-iso.conf
    then
        echo "; Found"
    else
        echo "; NOT Found"
    fi
    echo ""
    exit
}

keep_first_del_others() {
    shift
    if [ -n "$*" ]
    then
        rm -f $*
    fi
}

while [ -n "${1}" ]
do
    case "$1" in
        -h|--help)
            SHOW_HELP=1
        ;;
        -d|--debug)
            set -x
        ;;
        -e|--error)
            set -e
        ;;
        -v|--verbose)
            SILENT=""
            QUIET=""
        ;;
        --distro)
            shift
            ISO_DISTRO=$1
        ;;
        -s|--storage)
            shift
            ISO_STORAGE=$1
        ;;
    esac
    shift
done

if [ ${SHOW_HELP} -eq 1 ]
then
    show_help
fi

if [ "9" = "${ISO_DISTRO:0:1}" ]
then
    stream=9
else
    stream=8
fi

rm -f ${ISO_STORAGE}/CentOS-Stream-${stream}-*.SHA*

keep_first_del_others $(ls -v -r ${ISO_STORAGE}/CentOS-Stream-${stream}-*)
