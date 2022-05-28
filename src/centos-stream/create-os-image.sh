#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
#
# SPDX-License-Identifier: GPL-3.0-or-later

##################  start default config  ##################
VM_NAME=vm001
VM_DEV_NET="virtio-net-pci"                               # VM type NIC 
VM_MONITOR="" #${HOME}/.cache/qemu/${VM_NAME}-vm-monitor.sock # Monitor unix socket
VM_MEM=2048                                               # VM RAM
VM_CPU=host                                               # CPU type
VM_SMP="cpus=4,cores=2,threads=2,sockets=1"               # SMP
VM_SERIAL=none                                            # VM Serial 
VM_IMG_1=""                                               # VM Image 1
VM_IMG_FMT_1=qcow2       # raw|qcow2|luks|vmdk|vpc|VHDX
VM_IMG_CACHE_1=writeback # writethrough|writeback(Default)|none|directsync|unsafe
VM_IMG_2=""                                               # VM Image 2
VM_IMG_FMT_2=qcow2       # raw|qcow2|luks|vmdk|vpc|VHDX
VM_IMG_CACHE_2=writeback # writethrough|writeback(Default)|none|directsync|unsafe
VM_ISO_1=""                                               # VM ISO 1
VM_ISO_2=""                                               # VM ISO 2
VM_EXTRA_BLOCKS=""                                        # Extra VM disk images
VM_BOOT_IMG=0                                             # VM Image 1 bootindex
VM_BOOT_ISO=1                                             # VM ISO 1 bootindex
VM_NETDEV=user                                            # user|tap
VM_TAP=""                                                 # Network tap device name
VM_BRIDGE=""                                              # Network bridge name
VM_NETDEV_EXTRA=""                                        # Extra config filled in my_setup
VM_MACADDRESS=52:54:00:a1:b2:c3                           #
VM_OVMF_CODE=${HOME}/.local/share/qemu/OVMF_CODE.fd
VM_OVMF_VARS=${HOME}/.local/share/qemu/OVMF_VARS-${VM_NAME}.fd
VM_KERNEL=""
VM_INITRD=""
VM_KCMDLINE=""
VM_LOOP=""
VM_KS=""
EXTRA_QEMU_ARGS=""       # -hdd fat:/my_directory
##################  end default config  ###################

# empty image
#sudo qemu-img create -f qcow2 -o lazy_refcounts=on,preallocation=metadata miguelinux-cs9.qcow2 20G

# Where is the qemu binary
QEMU_BIN=$(command -v qemu-system-x86_64)
KERNEL_DIR=""

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

my_setup ()
{
    if [ -z "${VM_IMG_1}" ]
    then
        die "No VM image found"
    fi
    if [ -z "${VM_ISO_1}" ]
    then
        die "No ISO image found"
    fi
    if [ -z "${VM_LOOP}" ]
    then
        die "No loop device given"
    fi
    if [ -n "${VM_IMG_2}" ]
    then
        VM_EXTRA_BLOCKS+=" -drive file=${VM_IMG_2},format=${VM_IMG_FMT_2},cache=${VM_IMG_CACHE_2},if=none,index=1,id=disk1"
        VM_EXTRA_BLOCKS+=" -device ide-hd,bus=ide.0,drive=disk1"
    fi
    if [ -n "${VM_ISO_1}" ]
    then
        VM_EXTRA_BLOCKS+=" -drive file=${VM_ISO_1},if=none,format=raw,readonly=on,index=2,id=cd0"
        VM_EXTRA_BLOCKS+=" -device ide-cd,bus=ide.0,drive=cd0,bootindex=${VM_BOOT_ISO}"
    fi
    if [ -n "${VM_ISO_2}" ]
    then
        VM_EXTRA_BLOCKS+=" -drive file=${VM_ISO_2},if=none,format=raw,readonly=on,index=3,id=cd1"
        VM_EXTRA_BLOCKS+=" -device ide-cd,bus=ide.1,drive=cd1"
    fi

    if [ ! -f "${VM_OVMF_CODE}" ]
    then
        if [ -f /usr/share/qemu/OVMF_CODE.fd ]
        then
            mkdir -p ${VM_OVMF_CODE%/*}
            cp /usr/share/qemu/OVMF_CODE.fd ${VM_OVMF_CODE}
        elif [ -f /usr/share/edk2/ovmf/OVMF_CODE.fd ]
        then
            mkdir -p ${VM_OVMF_CODE%/*}
            cp /usr/share/edk2/ovmf/OVMF_CODE.fd ${VM_OVMF_CODE}
        else
            die "Can not find OVMF_CODE.fd file"
        fi
    fi

    if [ ! -f "${VM_OVMF_VARS}" ]
    then
        if [ -f /usr/share/qemu/OVMF_VARS.fd ]
        then
            mkdir -p ${VM_OVMF_VARS%/*}
            cp /usr/share/qemu/OVMF_VARS.fd ${VM_OVMF_VARS}
        elif [ -f /usr/share/edk2/ovmf/OVMF_VARS.fd ]
        then
            mkdir -p ${VM_OVMF_VARS%/*}
            cp /usr/share/edk2/ovmf/OVMF_VARS.fd ${VM_OVMF_VARS}
        else
            die "Can not find OVMF_VARS.fd file"
        fi
    fi

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

parse_args ()
{
    while [ -n "${1}" ]
    do
        case "$1" in
            -d|--debug)
                set -x
            ;;
            -e|--error)
                set -e
            ;;
            -i | --install)
                VM_DEV_NET="e1000"
            ;;
            -m)
                shift
                VM_MEM=$1
            ;;
            -cdrom)
                shift
                VM_ISO_1=$1
            ;;
            -cdrom2)
                shift
                VM_ISO_2=$1
            ;;
            -hda)
                shift
                VM_IMG_1=$1
            ;;
            -hdb)
                shift
                VM_IMG_2=$1
            ;;
            -boot)
                shift
                if [ ${1} = "d" ]
                then
                    VM_BOOT_IMG=1
                    VM_BOOT_ISO=0
                fi
                if [ ${1} = "kernel" ]
                then
                    VM_BOOT_IMG=1
                    VM_BOOT_ISO=2
                fi
            ;;
            -serial)
                shift
                VM_SERIAL=$1
            ;;
            -name)
                shift
                VM_NAME=$1
            ;;
            -kernel)
                shift
                VM_KERNEL=$1
            ;;
            -initrd)
                shift
                VM_INITRD=$1
            ;;
            -append)
                shift
                VM_KCMDLINE=$1
            ;;
            -l|--loop)
                shift
                VM_LOOP=$1
            ;;
            -ks|--kickstart)
                shift
                VM_KS=$1
            ;;
            -c|--command)
                shift
                # Create cache dir if not exist
                mkdir -p ${HOME}/.cache/qemu

                # Ensure VM_MONITOR
                if [ -z "${VM_MONITOR}" ]
                then
                    VM_MONITOR=${HOME}/.cache/qemu/${VM_NAME}-vm-monitor.sock # Monitor unix socket
                fi
                if [ -S ${VM_MONITOR} ]
                then
                    echo "$@" | socat - unix-connect:${VM_MONITOR}
                    exit 0
                else
                    die "No ${VM_MONITOR} file found"
                fi
            ;;
            -f|--config)
                shift
                if [ -e ${HOME}/.config/qemu-script/$1 ]
                then
                    source ${HOME}/.config/qemu-script/$1
                else
                    if [ -e $1 ]
                    then
                        source $1
                    else
                        die "Config file ($1) not found"
                    fi
                fi
            ;;
            *)
                EXTRA_QEMU_ARGS="${EXTRA_QEMU_ARGS} ${1}"
            ;;
        esac
        shift
    done
}

extract_kernel ()
{
    if [ ! -e ${VM_ISO_1} ]
    then
        die "${VM_ISO_1} does not exist"
    fi

    KERNEL_DIR=$(mktemp -d /tmp/create-os-image.XXXXXX)

    if ! my_sudo losetup -P ${VM_LOOP} ${VM_ISO_1}
    then
        rm -rf ${KERNEL_DIR}
        die "Could not create the ${VM_LOOP} device"
    fi

    mkdir -p ${KERNEL_DIR}/${VM_LOOP}p1

    if ! my_sudo mount -o ro /dev/${VM_LOOP}p1 ${KERNEL_DIR}/${VM_LOOP}p1
    then
        my_sudo losetup -d /dev/${VM_LOOP}
        rm -rf ${KERNEL_DIR}
        die "Could not mount the ${VM_LOOP} device"
    fi

    if [ -z "${VM_KERNEL}" ]
    then
        if [ ! -e ${KERNEL_DIR}/${VM_LOOP}p1/images/pxeboot/vmlinuz ]
        then
            my_sudo umount /dev/${VM_LOOP}p1
            my_sudo losetup -d /dev/${VM_LOOP}
            rm -rf ${KERNEL_DIR}
            die "vmlinuz not found at /images/pxeboot"
        fi

        cp ${KERNEL_DIR}/${VM_LOOP}p1/images/pxeboot/vmlinuz ${KERNEL_DIR}
        VM_KERNEL=${KERNEL_DIR}/vmlinuz
    fi

    if [ -z "${VM_INITRD}" ]
    then
        if [ ! -e ${KERNEL_DIR}/${VM_LOOP}p1/images/pxeboot/initrd.img ]
        then
            my_sudo umount /dev/${VM_LOOP}p1
            my_sudo losetup -d /dev/${VM_LOOP}
            rm -rf ${KERNEL_DIR}
            die "initrd not found at /images/pxeboot"
        fi

        cp ${KERNEL_DIR}/${VM_LOOP}p1/images/pxeboot/initrd.img ${KERNEL_DIR}
        VM_INITRD=${KERNEL_DIR}/initrd.img
    fi

    if [ -z "${VM_KCMDLINE}" ]
    then
        if [ ! -e ${KERNEL_DIR}/${VM_LOOP}p1/EFI/BOOT/grub.cfg ]
        then
            my_sudo umount /dev/${VM_LOOP}p1
            my_sudo losetup -d /dev/${VM_LOOP}
            rm -rf ${KERNEL_DIR}
            die "grub.cfg not found at /EFI/BOOT"
        fi
        VM_KCMDLINE=$(grep -m 1 vmlinuz ${KERNEL_DIR}/${VM_LOOP}p1/EFI/BOOT/grub.cfg \
                            | sed -e "s/^[[:space:]]*//" \
                            | cut -f 3- -d " ")
    fi

    my_sudo umount /dev/${VM_LOOP}p1
    my_sudo losetup -d /dev/${VM_LOOP}

    if [ -n "${VM_KS}" ]
    then
        if [ ! -e ${VM_KS} ]
        then
            die "${VM_KS}: not found"
        fi

        local kickstart_file=$(realpath ${VM_KS})

        mkdir ${KERNEL_DIR}/initrd
        pushd ${KERNEL_DIR}/initrd > /dev/null
        cp ${kickstart_file} ks.cfg
        find . | cpio --quiet --create --format=newc > ${KERNEL_DIR}/ks.img
        popd > /dev/null
        cat ${KERNEL_DIR}/ks.img ${VM_INITRD} > ${KERNEL_DIR}/initrd-ks.img
        VM_INITRD=${KERNEL_DIR}/initrd-ks.img
        VM_KCMDLINE="inst.ks=file:/ks.cfg inst.text inst.cmdline ${VM_KCMDLINE}"
        VM_KCMDLINE="${VM_KCMDLINE} console=tty0 console=ttyS0,115200n8 earlyprintk=ttyS0,115200n8"
    fi
}

run_qemu ()
{
    ${QEMU_BIN}                                                         \
        -name ${VM_NAME}                                                \
        -cpu  ${VM_CPU}                                                 \
        -machine type=q35,accel=kvm,usb=on                              \
        -enable-kvm                                                     \
        -smp ${VM_SMP}                                                  \
        -m ${VM_MEM}                                                    \
        -rtc base=localtime                                             \
        -monitor unix:${VM_MONITOR},server,nowait                       \
        -serial ${VM_SERIAL}                                            \
        -parallel none                                                  \
        -display none                                                   \
        -nographic                                                      \
        -device intel-hda                                               \
        -device hda-duplex                                              \
        -drive file=${VM_OVMF_CODE},if=pflash,format=raw,unit=0,readonly=on \
        -drive file=${VM_OVMF_VARS},if=pflash,format=raw,unit=1         \
        -drive file=${VM_IMG_1},format=${VM_IMG_FMT_1},cache=${VM_IMG_CACHE_1},if=none,index=0,id=disk0 \
        -device virtio-blk-pci,drive=disk0,bootindex=${VM_BOOT_IMG}     \
        ${VM_EXTRA_BLOCKS}                                              \
        -spice port=5924,disable-ticketing=on                           \
        -device qxl-vga                                                 \
        -device virtio-serial                                           \
        -netdev ${VM_NETDEV},id=mynet0${VM_NETDEV_EXTRA}                \
        -device ${VM_DEV_NET},netdev=mynet0,mac=${VM_MACADDRESS}        \
        -chardev spicevmc,id=vdagent,name=vdagent                       \
        -device virtserialport,chardev=vdagent,name=com.redhat.spice.0  \
        -object rng-random,id=virtio-rng0,filename=/dev/random          \
        -device virtio-rng-pci,rng=virtio-rng0,id=rng0,bus=pcie.0,addr=0x9 \
        -device qemu-xhci,id=usb                                        \
        -device usb-tablet,bus=usb.0                                    \
        -chardev spicevmc,name=usbredir,id=usbredirchardev1             \
        -device usb-redir,chardev=usbredirchardev1,id=usbredirdev1      \
        -chardev spicevmc,name=usbredir,id=usbredirchardev2             \
        -device usb-redir,chardev=usbredirchardev2,id=usbredirdev2      \
        -chardev spicevmc,name=usbredir,id=usbredirchardev3             \
        -device usb-redir,chardev=usbredirchardev3,id=usbredirdev3      \
        -global ICH9-LPC.disable_s3=1                                   \
        -global ICH9-LPC.disable_s4=1                                   \
        -kernel ${VM_KERNEL}                                            \
        -initrd ${VM_INITRD}                                            \
        -append "${VM_KCMDLINE}"                                        \
        ${EXTRA_QEMU_ARGS}
}

clean_up ()
{
    my_sudo rm -rf ${KERNEL_DIR}
}

############################### main ###############################

if [ -e ${HOME}/.config/qemu-script/${0##*/}.conf ]
then
    source ${HOME}/.config/qemu-script/${0##*/}.conf
fi
parse_args $@
is_running
my_setup
extract_kernel
run_qemu
clean_up
