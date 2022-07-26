#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
#
# SPDX-License-Identifier: GPL-3.0-or-later

ISO_DISTRO=8-stream
ISO_STORAGE=.
ISO_DIR=/tmp/iso_dir
ISO_LOOP=""

SILENT="--silent"
QUIET="--quiet"

SHOW_HELP=0

### Get user config
if [ -e ${HOME}/.config/qemu-script/${0##*/}.conf ]
then
    source ${HOME}/.config/qemu-script/${0##*/}.conf
fi

die ()
{
    >&2 echo -e "${*}"
    exit 1
}

my_sudo ()
{
    if [ ${UID} != "0" ]
    then
        sudo $*
    else
        $*
    fi
    return $?
}

show_help() {
    echo "Usage: $0 [parameters]"
    echo ""
    echo "PARAMETERS"
    echo ""
    echo "-v, --verbose      Shows commands output"
    echo "-d, --debug        Set debug mode in bash, i.e. set -x"
    echo "-e, --error        Set error mode in bash, i.e. set -e"
    echo "--distro DISTRO    Set the url DISTRO name part, i.e. 9-stream"
    echo "--dir DIRECTORY    Set the url DIRECTORY name part"
    echo "-s, --storage PATH Set the PATH to save ISO file"
    echo "-h, --help         Shows this help"
    echo ""
    echo "Current setup is:"
    echo "  Distro  = ${ISO_DISTRO}"
    echo "  Dir     = ${ISO_DIR}"
    echo "  Storage = ${ISO_STORAGE}"
    echo "  Loop    = ${ISO_LOOP}"
    echo ""
    echo -n "config file at: $HOME/.config/qemu-script/${0##*/}.conf"
    if test -f $HOME/.config/qemu-script/${0##*/}.conf
    then
        echo "; Found"
    else
        echo "; NOT Found"
    fi
    echo ""
    exit
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
        --dir)
            shift
            ISO_DIR=$1
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

my_setup ()
{
    if [ "9" = "${ISO_DISTRO:0:1}" ]
    then
        ISO_NAME=$(ls ${ISO_STORAGE}/CentOS-Stream-9-*-x86_64-dvd1.iso)
    else
        ISO_NAME=$(ls ${ISO_STORAGE}/CentOS-Stream-8-x86_64-*-dvd1.iso)
    fi

    if [ ! -f ${ISO_NAME} ]
    then
        die "${ISO_NAME}: Not found"
    fi

    if [ -z "${ISO_LOOP}" ]
    then
        die "No loop device given"
    fi

    if [ -d "${ISO_DIR}" ]
    then
        die "No directory to work (ISO_DIR) found"
    fi
}

copy_iso ()
{
    ISO_TMP=$(mktemp -d /tmp/create-custom-iso.XXXXXX)

    if ! my_sudo losetup -P ${ISO_LOOP} ${ISO_NAME}
    then
        rm -rf ${ISO_TMP}
        die "Could not create the ${ISO_LOOP} device"
    fi

    mkdir -p ${ISO_TMP}/${ISO_LOOP}p1

    if ! my_sudo mount -o ro /dev/${ISO_LOOP}p1 ${ISO_TMP}/${ISO_LOOP}p1
    then
        my_sudo losetup -d /dev/${ISO_LOOP}
        rm -rf ${ISO_TMP}
        die "Could not mount the ${ISO_LOOP} device"
    fi

    my_sudo umount /dev/${ISO_LOOP}p1
    my_sudo losetup -d /dev/${ISO_LOOP}
    my_sudo rm -rf ${ISO_TMP}
}

#################################    main    #################################

my_setup
copy_iso

