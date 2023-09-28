#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
#
# SPDX-License-Identifier: GPL-3.0-or-later

##################  start default config  ##################
VM_NAME=vm001
VM_DEV_NET="virtio-net-pci"                               # VM type NIC
VM_MONITOR="" #"${HOME}/.cache/qemu/${VM_NAME}-vm-monitor.sock" # Monitor unix socket
VM_MEM=2048                                               # VM RAM
VM_CPU=host                                               # CPU type
VM_SMP="cpus=4,cores=2,threads=2,sockets=1"               # SMP
VM_SERIAL=none                                            # VM Serial
VM_RTC_WIN="" #"-rtc base=localtime"  # if OS is windows set to localtime
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
        if [ -f /usr/share/qemu/OVMF_CODE.fd ]
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
        if [ -f /usr/share/qemu/OVMF_VARS.fd ]
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

run_qemu ()
{
    ${QEMU_BIN}                                                         \
        ${QEMU_DAEMONIZE}                                               \
        -name ${VM_NAME}                                                \
        -cpu  ${VM_CPU}                                                 \
        -machine type=q35,accel=kvm,usb=on,nvdimm=on,cxl=on             \
        -enable-kvm                                                     \
        -smp ${VM_SMP}                                                  \
        -m ${VM_MEM}                                                    \
        ${VM_RTC_WIN}                                                   \
        -monitor unix:${VM_MONITOR},server,nowait                       \
        -serial ${VM_SERIAL}                                            \
        -parallel none                                                  \
        -display none                                                   \
        -nographic                                                      \
        -device intel-hda                                               \
        -device hda-duplex                                              \
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
        -debugcon file:/tmp/uefi_debug.log                              \
        -global isa-debugcon.iobase=0x402                               \
        -object memory-backend-file,id=cxl-mem0,share=on,mem-path=${VM_PMEM_DIR}/cxltest0.raw,size=256M \
        -object memory-backend-file,id=cxl-mem1,share=on,mem-path=${VM_PMEM_DIR}/cxltest1.raw,size=256M \
        -object memory-backend-file,id=cxl-mem2,share=on,mem-path=${VM_PMEM_DIR}/cxltest2.raw,size=256M \
        -object memory-backend-file,id=cxl-mem3,share=on,mem-path=${VM_PMEM_DIR}/cxltest3.raw,size=256M \
        -object memory-backend-file,id=cxl-lsa0,share=on,mem-path=${VM_PMEM_DIR}/lsa0.raw,size=1K \
        -object memory-backend-file,id=cxl-lsa1,share=on,mem-path=${VM_PMEM_DIR}/lsa1.raw,size=1K \
        -object memory-backend-file,id=cxl-lsa2,share=on,mem-path=${VM_PMEM_DIR}/lsa2.raw,size=1K \
        -object memory-backend-file,id=cxl-lsa3,share=on,mem-path=${VM_PMEM_DIR}/lsa3.raw,size=1K \
        -device pxb-cxl,id=cxl.0,bus=pcie.0,bus_nr=53 \
        -device pxb-cxl,id=cxl.1,bus=pcie.0,bus_nr=191 \
        -device cxl-rp,id=hb0rp0,bus=cxl.0,chassis=0,slot=0,port=0 \
        -device cxl-rp,id=hb0rp1,bus=cxl.0,chassis=0,slot=1,port=1 \
        -device cxl-rp,id=hb1rp0,bus=cxl.1,chassis=0,slot=2,port=0 \
        -device cxl-rp,id=hb1rp1,bus=cxl.1,chassis=0,slot=3,port=1 \
        -device cxl-type3,bus=hb0rp0,memdev=cxl-mem0,id=cxl-dev0,lsa=cxl-lsa0 \
        -device cxl-type3,bus=hb0rp1,memdev=cxl-mem1,id=cxl-dev1,lsa=cxl-lsa1 \
        -device cxl-type3,bus=hb1rp0,memdev=cxl-mem2,id=cxl-dev2,lsa=cxl-lsa2 \
        -device cxl-type3,bus=hb1rp1,memdev=cxl-mem3,id=cxl-dev3,lsa=cxl-lsa3 \
        -M cxl-fmw.0.targets.0=cxl.0,cxl-fmw.0.size=4G,cxl-fmw.0.interleave-granularity=8k,cxl-fmw.1.targets.0=cxl.0,cxl-fmw.1.targets.1=cxl.1,cxl-fmw.1.size=4G,cxl-fmw.1.interleave-granularity=8k \
        -snapshot \
        -object memory-backend-ram,id=mem0,size=2048M        \
        -numa node,nodeid=0,memdev=mem0,        \
        -numa cpu,node-id=0,socket-id=0        \
        -object memory-backend-ram,id=mem1,size=2048M        \
        -numa node,nodeid=1,memdev=mem1,        \
        -numa cpu,node-id=1,socket-id=1        \
        -object memory-backend-ram,id=mem2,size=2048M        \
        -numa node,nodeid=2,memdev=mem2,        \
        -object memory-backend-ram,id=mem3,size=2048M        \
        -numa node,nodeid=3,memdev=mem3,        \
        -numa node,nodeid=4,        \
        -object memory-backend-file,id=nvmem0,share=on,mem-path=${VM_PMEM_DIR}/nvdimm-0,size=16384M,align=1G        \
        -device nvdimm,memdev=nvmem0,id=nv0,label-size=2M,node=4        \
        -numa node,nodeid=5,        \
        -object memory-backend-file,id=nvmem1,share=on,mem-path=${VM_PMEM_DIR}/nvdimm-1,size=16384M,align=1G        \
        -device nvdimm,memdev=nvmem1,id=nv1,label-size=2M,node=5        \
        -numa dist,src=0,dst=0,val=10        \
        -numa dist,src=0,dst=1,val=21        \
        -numa dist,src=0,dst=2,val=12        \
        -numa dist,src=0,dst=3,val=21        \
        -numa dist,src=0,dst=4,val=17        \
        -numa dist,src=0,dst=5,val=28        \
        -numa dist,src=1,dst=1,val=10        \
        -numa dist,src=1,dst=2,val=21        \
        -numa dist,src=1,dst=3,val=12        \
        -numa dist,src=1,dst=4,val=28        \
        -numa dist,src=1,dst=5,val=17        \
        -numa dist,src=2,dst=2,val=10        \
        -numa dist,src=2,dst=3,val=21        \
        -numa dist,src=2,dst=4,val=28        \
        -numa dist,src=2,dst=5,val=28        \
        -numa dist,src=3,dst=3,val=10        \
        -numa dist,src=3,dst=4,val=28        \
        -numa dist,src=3,dst=5,val=28        \
        -numa dist,src=4,dst=4,val=10        \
        -numa dist,src=4,dst=5,val=28        \
        -numa dist,src=5,dst=5,val=10        \
        ${EXTRA_QEMU_ARGS}

#        -object memory-backend-file,id=cxl-mem1,share=on,mem-path=/tmp/cxltest.raw,size=256M \
#        -object memory-backend-file,id=cxl-lsa1,share=on,mem-path=/tmp/lsa.raw,size=256M \
#        -device pxb-cxl,bus_nr=12,bus=pcie.0,id=cxl.1 \
#        -device cxl-rp,port=0,bus=cxl.1,id=root_port13,chassis=0,slot=2 \
#        -device cxl-type3,bus=root_port13,memdev=cxl-mem1,lsa=cxl-lsa1,id=cxl-pmem0 \
#        -M cxl-fmw.0.targets.0=cxl.1,cxl-fmw.0.size=4G \
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
run_qemu
