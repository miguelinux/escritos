#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
#
# SPDX-License-Identifier: GPL-3.0-or-later

set -e

if [ ! -f debian/rules ]
then
    echo "No debian/rules found"
    exit 1
fi

deb_pkg=$(dpkg-parsechangelog -S Source)

if [ "$deb_pkg" != "linux" ]
then
    echo "No linux debian source"
    exit 2
fi

ARCH=$(dpkg --print-architecture)
FEATURESET=none
# User ARCH on amd64
FLAVOUR=$ARCH

deb_kernel_ver=$(dpkg-parsechangelog -S Version)
kernel_ver=${deb_kernel_ver%-*}

if [ -f Makefile ]
then
    kv=$(grep ^VERSION      Makefile | cut -f 3 -d \ )
    kp=$(grep ^PATCHLEVEL   Makefile | cut -f 3 -d \ )
    ks=$(grep ^SUBLEVEL     Makefile | cut -f 3 -d \ )
    ke=$(grep ^EXTRAVERSION Makefile | cut -f 3 -d \ )

    # Local Kernel Version
    lkv=$kv.$kp.$ks
    if [ -n "$ke" ]
    then
        lkv=$kv.$kp$ke
    fi

    if [ "$kernel_ver" != "$lkv" ]
    then
        debian/rules maintainerclean
        debian/rules clean
    fi
fi

deb_kernel_file=linux_${kernel_ver}.orig.tar.xz

if [ ! -f ../${deb_kernel_file} ]
then
    kernel_file=linux-${kernel_ver}.tar.xz
    kernel_url=https://cdn.kernel.org/pub/linux/kernel/v6.x

    if echo $kernel_ver | grep --quiet \~
    then
        # kernel version fixed
        kvf=$(echo $kernel_ver | tr \~  -)
        kernel_file=linux-${kvf}.tar.gz
        kernel_url=https://git.kernel.org/torvalds/t
    fi

    curl -L -o ../${deb_kernel_file} ${kernel_url}/${kernel_file}
fi

mkdir -p ../orig

if echo $kernel_ver | grep --quiet \~
then
    kvf=$(echo $kernel_ver | tr \~  -)
    ln -s -f linux-${kvf} ../orig/linux-${kernel_ver}
fi

debian/rules orig
set +e
debian/rules debian/control
set -e
dpkg-architecture -a$ARCH -c make -f debian/rules.gen setup_${ARCH}_${FEATURESET}_${FLAVOUR}
