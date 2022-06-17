#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
#
# SPDX-License-Identifier: GPL-3.0-or-later

ISO_URL=http://mirror.stream.centos.org
ISO_DISTRO=9-stream
ISO_DIR=BaseOS/x86_64/iso
ISO_STORAGE=.

# ISO_URL=http://mirror.arizona.edu
# ISO_DISTRO=centos/8-stream
# ISO_DIR=isos/x86_64
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
    echo "--url URL          Set the base URL to download"
    echo "--dir DIRECTORY    Set the url DIRECTORY name part"
    echo "-s, --storage PATH Set the PATH to save ISO file"
    echo "-h, --help         Shows this help"
    echo ""
    echo "Current setup is:"
    echo "  URL     = ${ISO_URL}"
    echo "  Distro  = ${ISO_DISTRO}"
    echo "  Dir     = ${ISO_DIR}"
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
        --url)
            shift
            ISO_URL=$1
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

if [ "9" = "${ISO_DISTRO:0:1}" ]
then
    shafile=SHA256SUM
    datefield=4
    stream=9
else
    shafile=CHECKSUM
    datefield=5
    stream=8
fi

ISO_PAGE=${ISO_URL}/${ISO_DISTRO}/${ISO_DIR}

SHA256_LINE=$(curl ${SILENT} ${ISO_PAGE}/${shafile} | grep dvd | grep SHA256)
#SHA256=$(echo ${SHA256_LINE} | cut -f 4 -d \ )
LATEST_DATE=$(echo ${SHA256_LINE} | cut -f ${datefield} -d -)


if [ "${stream}" = "9" ]
then
    ISO_FILE=CentOS-Stream-9-${LATEST_DATE}-x86_64-dvd1.iso
else
    ISO_FILE=CentOS-Stream-8-x86_64-${LATEST_DATE}-dvd1.iso
fi

if test -f ${ISO_STORAGE}/${ISO_FILE}
then
    echo exit 0
fi

if [ "${stream}" = "9" ]
then
    curl ${SILENT} --location \
        -o ${ISO_STORAGE}/${ISO_FILE}.SHA256SUM \
           ${ISO_PAGE}/${ISO_FILE}.SHA256SUM
fi

curl ${SILENT} --location \
     -o ${ISO_STORAGE}/${ISO_FILE} \
        ${ISO_PAGE}/${ISO_FILE}

if [ "${stream}" = "9" ]
then
    pushd ${ISO_STORAGE} > /dev/null
    if ! sha256sum ${QUIET} -c ${ISO_STORAGE}/CentOS-Stream-9-${LATEST_DATE}-x86_64-dvd1.iso.SHA256SUM
    then
        echo >&2 "Bad sha256sum"
        rm -v ${ISO_STORAGE}/CentOS-Stream-9-${LATEST_DATE}-x86_64-dvd1.iso
        rm -v ${ISO_STORAGE}/CentOS-Stream-9-${LATEST_DATE}-x86_64-dvd1.iso.SHA256SUM
        popd >> /dev/null
        exit 1
    fi
    popd > /dev/null
fi

# Create a symlink to the latest downloaded image
ln --force --symbolic ${ISO_FILE} ${ISO_STORAGE}/CentOS-Stream-${stream}.iso
