#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
#
# SPDX-License-Identifier: GPL-3.0-or-later

##################  start default config  ##################
VM_NAME=vm001
VM_DEV_NET="virtio-net-pci"                               # VM type NIC
VM_MONITOR="" #"/run/user/${UID}/qemu/${VM_NAME}-vm-monitor.sock" # Monitor unix socket
VM_MEM=2048                                               # VM RAM
VM_CPU="host" #,migratable=on,hv-time=on,hv-relaxed=on,hv-vapic=on,hv-spinlocks=0x1fff,hv-vpindex=on,hv-runtime=on,hv-synic=on,hv-stimer=on,hv-stimer-direct=on,hv-reset=on,hv-vendor-id=KVM,hv-frequencies=on,hv-reenlightenment=on,hv-tlbflush=on,hv-ipi=on,hv-evmcs=on"
# Use ^^ options on VM_CPU when Windows
VM_SMP="4,sockets=4,cores=1,threads=1"               # SMP
VM_SERIAL=none                                            # VM Serial
VM_RTC_WIN=0 # 1 = windows, 0 = other
VM_TPM=0 # 1 = Use TPM, 0 = No use tpm
VM_SEC_BOOT=0 # 1 = use Secure Boot, 0 = don't use SB
VM_MACHINE_EXTRAS=",usb=on" #,vmport=off,smm=on,dump-guest-core=off"
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
VM_NET_USER_HOSTFWD=",hostfwd=tcp::10022-:22"             # Host forwarding
VM_NETDEV_EXTRA=""                                        # Extra config filled in my_setup
VM_MACADDRESS=52:54:00:a1:b2:c3                           #
VM_OVMF_CODE=${HOME}/.local/share/qemu/OVMF_CODE.fd
VM_OVMF_VARS=${HOME}/.local/share/qemu/OVMF_VARS-${VM_NAME}.fd
VM_SPICE_PORT=5924                                        # spice port
VM_SPICE_EXTRA=",disable-ticketing=on"                    # spice extra args
VM_PMEM_DIR=/tmp                                          # CXL, NVMDIMM files
VM_QEMU_BIN=""           # Path from another qemu binary
EXTRA_QEMU_ARGS=""       # -hdd fat:/my_directory
##################  end default config  ###################

# Where is the qemu binary
QEMU_BIN=$(command -v qemu-system-x86_64)
QEMU_DAEMONIZE="-daemonize"

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
    if [ -z "${VM_IMG_1}" ]
    then
        die "No VM image found"
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
        if [ -f /usr/share/OVMF/OVMF_CODE_4M.fd ]
        then
            # Debian Trixie
            mkdir -p ${VM_OVMF_CODE%/*}
            cp /usr/share/OVMF/OVMF_CODE_4M.fd ${VM_OVMF_CODE}
        elif [ -f /usr/share/qemu/OVMF_CODE.fd ]
        then
            mkdir -p ${VM_OVMF_CODE%/*}
            cp /usr/share/qemu/OVMF_CODE.fd ${VM_OVMF_CODE}
        elif [ -f /usr/share/edk2/ovmf/OVMF_CODE.fd ]
        then
            mkdir -p ${VM_OVMF_CODE%/*}
            cp /usr/share/edk2/ovmf/OVMF_CODE.fd ${VM_OVMF_CODE}
        elif [ -f /usr/share/edk2/ovmf/OVMF_CODE.cc.fd ]
        then
            mkdir -p ${VM_OVMF_CODE%/*}
            cp /usr/share/edk2/ovmf/OVMF_CODE.cc.fd ${VM_OVMF_CODE}
        elif [ -f /usr/share/OVMF/OVMF_CODE.fd ]
        then
            mkdir -p ${VM_OVMF_CODE%/*}
            cp /usr/share/OVMF/OVMF_CODE.fd ${VM_OVMF_CODE}
        else
            die "Can not find OVMF_CODE.fd file"
        fi
    fi

    if [ ! -f "${VM_OVMF_VARS}" ]
    then
        if [ -f /usr/share/OVMF/OVMF_VARS_4M.fd ]
        then
            # Debian Trixie
            mkdir -p ${VM_OVMF_VARS%/*}
            cp /usr/share/OVMF/OVMF_VARS_4M.fd ${VM_OVMF_VARS}
        elif [ -f /usr/share/qemu/OVMF_VARS.fd ]
        then
            mkdir -p ${VM_OVMF_VARS%/*}
            cp /usr/share/qemu/OVMF_VARS.fd ${VM_OVMF_VARS}
        elif [ -f /usr/share/edk2/ovmf/OVMF_VARS.fd ]
        then
            mkdir -p ${VM_OVMF_VARS%/*}
            cp /usr/share/edk2/ovmf/OVMF_VARS.fd ${VM_OVMF_VARS}
        elif [ -f /usr/share/edk2/ovmf/OVMF_VARS.secboot.fd ]
        then
            mkdir -p ${VM_OVMF_VARS%/*}
            cp /usr/share/edk2/ovmf/OVMF_VARS.secboot.fd ${VM_OVMF_VARS}
        elif [ -f /usr/share/OVMF/OVMF_VARS.fd ]
        then
            mkdir -p ${VM_OVMF_VARS%/*}
            cp /usr/share/OVMF/OVMF_VARS.fd ${VM_OVMF_VARS}
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
        if test -n "${VM_NET_USER_HOSTFWD}"
        then
            VM_NETDEV_EXTRA="${VM_NETDEV_EXTRA}${VM_NET_USER_HOSTFWD}"
        fi
    fi

    # Create cache dir if not exist
    mkdir -p /run/user/${UID}/qemu

    # Ensure VM_MONITOR
    if [ -z "${VM_MONITOR}" ]
    then
        VM_MONITOR=/run/user/${UID}/qemu/${VM_NAME}-vm-monitor.sock # Monitor unix socket
    fi

    QEMU_RTC=""
    if [ "${VM_RTC_WIN}" = "1" ]
    then
        QEMU_RTC="-rtc base=localtime,driftfix=slew"
        QEMU_RTC+=" -global kvm-pit.lost_tick_policy=delay"
    fi

    QEMU_SEC_BOOT=""
    if [ "${VM_SEC_BOOT}" = "1" ]
    then
        QEMU_SEC_BOOT="-global driver=cfi.pflash01,property=secure,value=on"
    fi

    if [ -z "${QEMU_BIN}" ]
    then
        if [ -x /usr/libexec/qemu-kvm ]
        then
            QEMU_BIN=/usr/libexec/qemu-kvm
        fi
    fi

    if [ -n "${VM_QEMU_BIN}" ]
    then
        if [ -x ${VM_QEMU_BIN} ]
        then
            QEMU_BIN=${VM_QEMU_BIN}
        fi
    fi

    if [ "${VM_SERIAL}" = "stdio" ]
    then
        QEMU_DAEMONIZE=""
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
            ;;
            -serial)
                shift
                VM_SERIAL=$1
            ;;
            -name)
                shift
                VM_NAME=$1
            ;;
            -c|--command)
                shift
                # Create cache dir if not exist
                mkdir -p /run/user/${UID}/qemu

                # Ensure VM_MONITOR
                if [ -z "${VM_MONITOR}" ]
                then
                    VM_MONITOR=/run/user/${UID}/qemu/${VM_NAME}-vm-monitor.sock # Monitor unix socket
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
                if [ -e ${HOME}/.config/qemu-scripts/$1 ]
                then
                    source ${HOME}/.config/qemu-scripts/$1
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

run_swtpm ()
{
    QEMU_TPM=""
    if [ "${VM_TPM}" = "1" ]
    then
        if [ ! -e /usr/bin/swtpm ]
        then
            die  "No /usr/bin/swtpm Found"
        fi

        # Create cache dir if not exist
        mkdir -p ${HOME}/.cache/swtpm/${VM_NAME}/tpm2

        /usr/bin/swtpm socket \
            --ctrl type=unixio,path=/run/user/${UID}/qemu/${VM_NAME}-swtpm.sock,mode=0600 \
            --tpmstate dir=${HOME}/.cache/swtpm/${VM_NAME}/tpm2,mode=0600 \
            --log file=${HOME}/.cache/swtpm/${VM_NAME}/${VM_NAME}-swtpm.log \
            --terminate \
            --tpm2 \
            --daemon

        QEMU_TPM="-chardev socket,id=chrtpm,path=/run/user/${UID}/qemu/${VM_NAME}-swtpm.sock"
        QEMU_TPM+=" -tpmdev emulator,id=tpm-tpm0,chardev=chrtpm"
        QEMU_TPM+=" -device tpm-crb,id=tpm0,tpmdev=tpm-tpm0"
    fi
}

run_qemu ()
{
    ${QEMU_BIN}                                                         \
        ${QEMU_DAEMONIZE}                                               \
        -name ${VM_NAME}                                                \
        -cpu  ${VM_CPU}                                                 \
        -machine type=q35,accel=kvm${VM_MACHINE_EXTRAS}                 \
        -enable-kvm                                                     \
        -smp ${VM_SMP}                                                  \
        -m ${VM_MEM}                                                    \
        ${QEMU_RTC}                                                     \
        -monitor unix:${VM_MONITOR},server,nowait                       \
        -serial ${VM_SERIAL}                                            \
        -parallel none                                                  \
        -display none                                                   \
        -nographic                                                      \
        ${QEMU_TPM}                                                     \
        -device intel-hda                                               \
        -device hda-duplex                                              \
        ${QEMU_SEC_BOOT}                                                \
        -object iothread,id=io1                                         \
        -device virtio-blk-pci,drive=disk0,iothread=io1,bootindex=${VM_BOOT_IMG} \
        -drive file=${VM_OVMF_CODE},if=pflash,format=raw,unit=0,readonly=on \
        -drive file=${VM_OVMF_VARS},if=pflash,format=raw,unit=1         \
        -drive file=${VM_IMG_1},format=${VM_IMG_FMT_1},cache=${VM_IMG_CACHE_1},if=none,index=0,aio=native,cache.direct=on,id=disk0 \
        ${VM_EXTRA_BLOCKS}                                              \
        -spice port=${VM_SPICE_PORT}${VM_SPICE_EXTRA}                   \
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
        ${EXTRA_QEMU_ARGS}
}

############################### main ###############################
#
if [ -e /etc/qemu-scripts/${0##*/}.conf ]
then
    source /etc/qemu-scripts/${0##*/}.conf
fi
if [ -e ${HOME}/.config/qemu-scripts/${0##*/}.conf ]
then
    source ${HOME}/.config/qemu-scripts/${0##*/}.conf
fi

parse_args $@
is_running
my_setup
run_swtpm
run_qemu
