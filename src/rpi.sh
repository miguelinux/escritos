#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
#
# SPDX-License-Identifier: GPL-3.0-or-later

qemu-system-aarch64
    -m 1024
    -M raspi3
    -kernel kernel8.img
    -dtb bcm2710-rpi-3-b-plus.dtb
    -sd 2020-08-20-raspios-buster-armhf.img
    -append "console=ttyAMA0 root=/dev/mmcblk0p2 rw rootwait rootfstype=ext4"
    -nographic
    -device usb-net,netdev=net0
    -netdev user,id=net0,hostfwd=tcp::5555-:22
