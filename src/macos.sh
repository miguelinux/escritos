#!/bin/bash
#
# Based on https://github.com/foxlet/macOS-Simple-KVM

OSK="ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc"
VMDIR=$PWD
OVMF=$VMDIR/firmware
#export QEMU_AUDIO_DRV=pa
#QEMU_AUDIO_DRV=pa
VM_NAME=macOSX
VM_DEV_NET="e1000-82545em"                                  # VM type NIC
VM_MONITOR="${HOME}/.cache/qemu/${VM_NAME}-vm-monitor.sock" # Monitor unix socket

qemu-system-x86_64 \
    -daemonize                                                      \
    -name ${VM_NAME}                                                \
    -enable-kvm \
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
    -netdev user,id=net0 \
    -device e1000-82545em,netdev=net0,id=net0,mac=52:54:00:c9:18:27 \
    -device ich9-ahci,id=sata \
    -drive id=ESP,if=none,format=qcow2,file=ESP.qcow2 \
    -device ide-hd,bus=sata.2,drive=ESP \
    -drive id=SystemDisk,if=none,file=macos.qcow2 \
    -device ide-hd,bus=sata.3,drive=SystemDisk

#    -drive id=InstallMedia,format=raw,if=none,file=BaseSystem.img \
#    -device ide-hd,bus=sata.3,drive=InstallMedia \
