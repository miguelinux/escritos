#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
#
# SPDX-License-Identifier: GPL-3.0-or-later

ISO_DISTRO=8-stream
ISO_STORAGE=.
ISO_DIR=/tmp/iso_dir
ISO_LOOP=""

ANACONDA_FILES_DIR=/tmp/anaconda
RPM_DIR=/tmp/rpms
NEW_REPO_NAME=""
REPO_COMPS_FILE=""

SILENT="--silent"
QUIET="--quiet"
QUIET_X="-quiet"
QUIET_S="-quiet -no-progress"
VERBOSE=""
VERBOSE_R=""
SHOW_INFO=""

# Runtime fillled variables
ISO_CUSTOM=""
ISO_TMP=""

SHOW_HELP=0

die ()
{
    >&2 echo -e "${*}"
    exit 1
}

info ()
{
    if [ -n "${SHOW_INFO}" ]
    then
        echo -e "${*}"
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

my_cp ()
{
    local orig=$1
    local dest=$2

    if [ ! -e ${dest} ]
    then
        # Do a hard link instead of a copy
        if ! ln ${orig} ${dest} 2> /dev/null
        then
            cp ${orig} ${dest}
        fi
    fi
    if [ -d ${dest} ]
    then
        # Do a hard link instead of a copy
        if ! ln ${orig} ${dest} 2> /dev/null
        then
            cp ${orig} ${dest}
        fi
    fi
}

show_help ()
{
    echo "Usage: $0 [parameters]"
    echo ""
    echo "PARAMETERS"
    echo ""
    echo "-v, --verbose      Shows commands output"
    echo "-i, --info         Shows current step from script"
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
    echo -n "config file at: $HOME/.config/qemu-scripts/${0##*/}.conf"
    if test -f $HOME/.config/qemu-scripts/${0##*/}.conf
    then
        echo "; Found"
    else
        echo "; NOT Found"
    fi
    echo ""
    exit
}

my_setup ()
{
    if [ "9" = "${ISO_DISTRO:0:1}" ]
    then
        ISO_NAME=$(ls ${ISO_STORAGE}/CentOS-Stream-9-202*-x86_64-dvd1.iso)
    else
        ISO_NAME=$(ls ${ISO_STORAGE}/CentOS-Stream-8-x86_64-202*-dvd1.iso)
    fi

    if [ ! -f "${ISO_NAME}" ]
    then
        die "${ISO_NAME}: Not found"
    fi

    if [ -z "${ISO_LOOP}" ]
    then
        die "No loop device given"
    fi

    if [ ! -d "${ISO_DIR}" ]
    then
        die "${ISO_DIR}: No directory to work (ISO_DIR) found"
    fi

    if [ ! -d ${ANACONDA_FILES_DIR} ]
    then
        die "${ANACONDA_FILES_DIR}: anaconda files dir not found"
    fi

    if [ ! -d ${RPM_DIR} ]
    then
        die "${RPM_DIR}: RPM dir not found"
    fi

    if [ -z "${NEW_REPO_NAME}" ]
    then
        die "No new repo name (NEW_REPO_NAME) given"
    fi

    if [ -n ${REPO_COMPS_FILE} ]
    then
        if [ ! -e ${REPO_COMPS_FILE} ]
        then
            die "${REPO_COMPS_FILE}:  comps file not found"
        fi
    fi
}

copy_iso ()
{
    local rsync_param

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

    if [ "9" = "${ISO_DISTRO:0:1}" ]
    then
        rsync_param=""
    else
        #rsync_param="--exclude BaseOS --exclude AppStream"
        rsync_param=""
    fi

    ISO_CUSTOM=$(mktemp -d ${ISO_DIR}/create-custom-iso.XXXXXX)

    info "Copy ISO to ${ISO_CUSTOM}."
    my_sudo rsync -a ${VERBOSE_R} ${ISO_TMP}/${ISO_LOOP}p1/ ${ISO_CUSTOM} ${rsync_param}

    my_sudo umount /dev/${ISO_LOOP}p1
    my_sudo losetup -d /dev/${ISO_LOOP}
}

modify_iso ()
{
    if [ ! -f ${ISO_CUSTOM}/images/install.img ]
    then
        delete_tmp
        die "${ISO_CUSTOM}/images/install.img: not found"
    fi

    # Change permision for directory and file
    my_sudo chown -R ${UID} ${ISO_CUSTOM}
    find ${ISO_CUSTOM} -type d -exec chmod 755 {} \;

    info "Unsquash rootfs."
    my_sudo unsquashfs ${QUIET_S} -dest ${ISO_CUSTOM}/images/squashfs-root ${ISO_CUSTOM}/images/install.img

    mkdir -p ${ISO_TMP}/rootfs

    my_sudo mount ${ISO_CUSTOM}/images/squashfs-root/LiveOS/rootfs.img ${ISO_TMP}/rootfs

    ################## Anaconda Hacks ##################
    info "Applying anaconda hacks."
    for p in ${ANACONDA_FILES_DIR}/*.patch
    do
        if [ -f $p ]
        then
            my_sudo patch ${SILENT} -d ${ISO_TMP}/rootfs/usr/lib64/python3.6/site-packages -p1 < $p
        fi
    done

    for f in ${ANACONDA_FILES_DIR}/*.conf
    do
        if [ -f $f ]
        then
            my_sudo cp $f ${ISO_TMP}/rootfs/etc/anaconda/conf.d
        fi

    done
    ################## Anaconda Hacks END ##################

    my_sudo umount ${ISO_TMP}/rootfs
    my_sudo rm -f ${ISO_CUSTOM}/images/install.img
    info "Squash rootfs."
    my_sudo mksquashfs ${ISO_CUSTOM}/images/squashfs-root ${ISO_CUSTOM}/images/install.img ${QUIET_S} -comp xz -Xbcj x86
    my_sudo rm -rf ${ISO_CUSTOM}/images/squashfs-root

    # Update SHA256 from install.img at treeinfo file
    local install_sha256
    install_sha256=$(sha256sum ${ISO_CUSTOM}/images/install.img | cut -f 1 -d " ")

    my_sudo chmod 664 ${ISO_CUSTOM}/.treeinfo
    # Copy for debug later
    cp ${ISO_CUSTOM}/.treeinfo ${ISO_TMP}
    sed -i "/^images\/install/c images/install.img = sha256:${install_sha256}" ${ISO_CUSTOM}/.treeinfo

    my_sudo chmod 664 ${ISO_CUSTOM}/EFI/BOOT/BOOT.conf
    my_sudo chmod 664 ${ISO_CUSTOM}/EFI/BOOT/grub.cfg
    my_sudo chmod 664 ${ISO_CUSTOM}/isolinux/grub.conf
    my_sudo chmod 664 ${ISO_CUSTOM}/isolinux/isolinux.cfg

    info "Disable selinux."
    # Disable selinux
    sed -i "s/quiet/quiet selinux=0/g" ${ISO_CUSTOM}/EFI/BOOT/BOOT.conf
    sed -i "s/quiet/quiet selinux=0/g" ${ISO_CUSTOM}/EFI/BOOT/grub.cfg
    sed -i "s/quiet/quiet selinux=0/g" ${ISO_CUSTOM}/isolinux/grub.conf
    sed -i "s/quiet/quiet selinux=0/g" ${ISO_CUSTOM}/isolinux/isolinux.cfg

    # Boot from first option on CD
    sed -i "s/=\"1\"/=\"0\"/g" ${ISO_CUSTOM}/EFI/BOOT/BOOT.conf
    sed -i "s/=\"1\"/=\"0\"/g" ${ISO_CUSTOM}/EFI/BOOT/grub.cfg

    ################## Copy RPMs ##################

    info "Copy RPMs."
    mkdir -p ${ISO_CUSTOM}/${NEW_REPO_NAME}/Packages

    for f in $(find ${RPM_DIR} -name \*x86_64.rpm)
    do
        my_cp $f ${ISO_CUSTOM}/${NEW_REPO_NAME}/Packages
    done
    for f in $(find ${RPM_DIR} -name \*i686.rpm)
    do
        my_cp $f ${ISO_CUSTOM}/${NEW_REPO_NAME}/Packages
    done
    for f in $(find ${RPM_DIR} -name \*noarch.rpm)
    do
        my_cp $f ${ISO_CUSTOM}/${NEW_REPO_NAME}/Packages
    done

    local comps_param=""
    if [ -n ${REPO_COMPS_FILE} ]
    then
        my_sudo cp ${REPO_COMPS_FILE} ${ISO_CUSTOM}/${NEW_REPO_NAME}
        comps_param="-g ${REPO_COMPS_FILE##*/}"
    fi

    info "Create RPM repo."
    my_sudo createrepo_c ${QUIET} ${comps_param} ${ISO_CUSTOM}/${NEW_REPO_NAME}
    my_sudo rm ${ISO_CUSTOM}/${NEW_REPO_NAME}/${REPO_COMPS_FILE##*/}

    # add new repo section
    if [ -n ${REPO_COMPS_FILE} ]
    then
        echo "[variant-${NEW_REPO_NAME}]"            >> ${ISO_CUSTOM}/.treeinfo
        echo "id = ${NEW_REPO_NAME}"                 >> ${ISO_CUSTOM}/.treeinfo
        echo "name = ${NEW_REPO_NAME}"               >> ${ISO_CUSTOM}/.treeinfo
        echo "packages = ${NEW_REPO_NAME}/Packages"  >> ${ISO_CUSTOM}/.treeinfo
        echo "repository = ${NEW_REPO_NAME}"         >> ${ISO_CUSTOM}/.treeinfo
        echo "type = variant"                        >> ${ISO_CUSTOM}/.treeinfo
        echo "uid = ${NEW_REPO_NAME}"                >> ${ISO_CUSTOM}/.treeinfo
        echo ""                                      >> ${ISO_CUSTOM}/.treeinfo

        sed -i "/variants/c variants = AppStream,BaseOS,${NEW_REPO_NAME}" ${ISO_CUSTOM}/.treeinfo
    fi
}

create_iso ()
{
    local iso_label
    local iso_name
    local my_ww=$(date "+%V")
    # Work week hack
    let "my_ww=my_ww+1"

    if [ "9" = "${ISO_DISTRO:0:1}" ]
    then
        iso_name=CentOS-Stream-9-${NEW_REPO_NAME}-WW${my_ww}.$(date "+%u")-x86_64-dvd1.iso
        iso_label=CentOS-Stream-9-x86_64-dvd
    else
        iso_name=CentOS-Stream-8-x86_64-${NEW_REPO_NAME}-WW${my_ww}.$(date "+%u")-dvd1.iso
        iso_label=CentOS-Stream-8-x86_64-dvd
    fi

    info "Create ISO"
    xorrisofs ${VERBOSE} ${QUIET_X} -iso-level 3 \
       -o ${ISO_STORAGE}/${iso_name} \
       -R -J -V "${iso_label}" \
       --grub2-mbr /usr/lib/grub/i386-pc/boot_hybrid.img \
       -partition_offset 16 \
       -appended_part_as_gpt \
       -append_partition 2 C12A7328-F81F-11D2-BA4B-00A0C93EC93B ${ISO_CUSTOM}/images/efiboot.img \
       -iso_mbr_part_type EBD0A0A2-B9E5-4433-87C0-68B6B72699C7 \
       -c isolinux/boot.cat --boot-catalog-hide \
       -b isolinux/isolinux.bin \
       -no-emul-boot -boot-load-size 4 -boot-info-table --grub2-boot-info \
       -eltorito-alt-boot \
       -e '--interval:appended_partition_2:all::' -no-emul-boot \
       ${ISO_CUSTOM}
}

delete_tmp ()
{
    info "Clean ${ISO_CUSTOM} and ${ISO_TMP}"
    my_sudo rm -rf ${ISO_TMP}
    my_sudo rm -rf ${ISO_CUSTOM}
}

#################################    main    #################################

### Get user config
if [ -e ${HOME}/.config/qemu-scripts/${0##*/}.conf ]
then
    source ${HOME}/.config/qemu-scripts/${0##*/}.conf
fi

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
            QUIET_X=""
            QUIET_S=""
            VERBOSE="-v"
            VERBOSE_R="-v --progress"
        ;;
        -i|--info)
            SHOW_INFO="yes"
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

my_setup
copy_iso
modify_iso
create_iso
delete_tmp
