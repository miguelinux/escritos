#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
# Based on https://github.com/foxlet/macOS-Simple-KVM

OSK="ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc"
VMDIR=$PWD
OVMF=$VMDIR/firmware
#export QEMU_AUDIO_DRV=pa
#QEMU_AUDIO_DRV=pa
VM_NAME=macOSX
VM_NETDEV=user                                           # user|tap
VM_TAP=""                                                # Network tap device name
VM_BRIDGE=""                                             # Network bridge name
VM_NETDEV_EXTRA=""                                       # Extra config filled in my_setup
VM_DEV_NET="e1000-82545em"                               # VM type NIC
VM_MACADDRESS=52:54:00:c9:18:27
VM_MONITOR="${HOME}/.cache/qemu/${VM_NAME}-vm-monitor.sock" # Monitor unix socket

# Where is the qemu binary
QEMU_BIN=$(command -v qemu-system-x86_64)

die ()
{
    >&2 echo -e "${*}"
    exit 1
}

is_running ()
{
    if ps aux | grep qemu | grep --quiet "${VM_NAME}"
    then
        die "Looks like Qemu is already running (${VM_NAME})"
    fi
}

my_setup ()
{
    if test "tap" = "${VM_NETDEV}" \
        -a -n "${VM_TAP}" \
        -a -n "${VM_BRIDGE}"
    then
        VM_NETDEV_EXTRA=",ifname=${VM_TAP},script=no,downscript=no,br=${VM_BRIDGE}"
    else
        # Ensure we use user netdev
        VM_NETDEV=user
        VM_NETDEV_EXTRA=""
    fi

    # Create cache dir if not exist
    mkdir -p ${HOME}/.cache/qemu

    # Ensure VM_MONITOR
    if [ -z "${VM_MONITOR}" ]
    then
        VM_MONITOR=${HOME}/.cache/qemu/${VM_NAME}-vm-monitor.sock # Monitor unix socket
    fi

    if [ -z "${QEMU_BIN}" ]
    then
        if [ -x /usr/libexec/qemu-kvm ]
        then
            QEMU_BIN=/usr/libexec/qemu-kvm
        fi
    fi
}

run_qemu ()
{
  ${QEMU_BIN}                                                       \
    -daemonize                                                      \
    -name ${VM_NAME}                                                \
    -enable-kvm                                                     \
    -m 5G \
    -machine type=q35,accel=kvm,usb=on                              \
    -cpu Penryn,vendor=GenuineIntel,kvm=on,+sse3,+sse4.2,+aes,+xsave,+avx,+xsaveopt,+xsavec,+xgetbv1,+avx2,+bmi2,+smep,+bmi1,+fma,+movbe,+invtsc \
    -smp cpus=4,cores=2,threads=2,sockets=1                         \
    -rtc base=localtime                                             \
    -monitor unix:${VM_MONITOR},server,nowait                       \
    -serial none                                                    \
    -parallel none                                                  \
    -display none                                                   \
    -nographic                                                      \
    -device isa-applesmc,osk="$OSK" \
    -smbios type=2 \
    -drive if=pflash,format=raw,readonly=on,file="$OVMF/OVMF_CODE.fd" \
    -drive if=pflash,format=raw,file="$OVMF/OVMF_VARS-1024x768.fd" \
    -spice port=5924,disable-ticketing=on                           \
    -device qxl-vga                                                 \
    -device virtio-serial                                           \
    -device ich9-intel-hda -device hda-output \
    -usb -device usb-kbd -device usb-tablet \
    -device qemu-xhci,id=usb                                        \
    -device usb-tablet,bus=usb.0                                    \
    -chardev spicevmc,name=usbredir,id=usbredirchardev1             \
    -device usb-redir,chardev=usbredirchardev1,id=usbredirdev1      \
    -chardev spicevmc,name=usbredir,id=usbredirchardev2             \
    -device usb-redir,chardev=usbredirchardev2,id=usbredirdev2      \
    -chardev spicevmc,name=usbredir,id=usbredirchardev3             \
    -device usb-redir,chardev=usbredirchardev3,id=usbredirdev3      \
    -netdev ${VM_NETDEV},id=mynet0${VM_NETDEV_EXTRA}                \
    -device ${VM_DEV_NET},netdev=mynet0,mac=${VM_MACADDRESS}        \
    -device ich9-ahci,id=sata \
    -drive id=ESP,if=none,format=qcow2,file=ESP.qcow2 \
    -device ide-hd,bus=sata.2,drive=ESP \
    -drive id=SystemDisk,if=none,file=macos.qcow2 \
    -device ide-hd,bus=sata.3,drive=SystemDisk

#    -drive id=InstallMedia,format=raw,if=none,file=BaseSystem.img \
#    -device ide-hd,bus=sata.3,drive=InstallMedia \
}

if [ -e ${HOME}/.config/qemu-script/${0##*/}.conf ]
then
    source ${HOME}/.config/qemu-script/${0##*/}.conf
fi

my_setup
run_qemu

