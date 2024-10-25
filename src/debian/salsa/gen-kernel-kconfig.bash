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

dpkg-architecture -a$ARCH -c make -f debian/rules.gen setup_${ARCH}_${FEATURESET}_${FLAVOUR}
