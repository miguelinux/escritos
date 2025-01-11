#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
#
# SPDX-License-Identifier: GPL-3.0-or-later

contenedor=$1

if [ -z "${contenedor}" ]
then
    >&2 echo "Falta nombre del contenedor"
    exit 1
fi

if !  incus ls ${contenedor} | grep --quiet RUNNING
then
    >&2 echo "No se encontro el contenedor: ${contenedor} corriendo"
    exit 2
fi

source <(incus exec ${contenedor} cat /etc/os-release)

packages_to_install="git git-lfs tmux vim rsync curl"
packages_to_install_too="stow connect-proxy"

case $ID in
    #fedora)
        #dnf -y update
        #dnf -y install $packages_to_install
        #dnf -y install $packages_to_install_too
    #;;
    #centos)
        #dnf -y update
        #dnf -y install $packages_to_install
    #;;
    #debian|
    ubuntu)
        incus exec ${contenedor} -- apt-get -y update
        incus exec ${contenedor} -- apt-get -y upgrade
        incus exec ${contenedor} -- apt-get -y install $packages_to_install
        incus exec ${contenedor} -- apt-get -y install $packages_to_install_too
        incus exec ${contenedor} -- apt-get -y install openssh-server

        incus exec ${contenedor} --user 1000 --group 1000 -- mkdir -m 700 -p /home/ubuntu/.ssh
        incus file push incus.key.pub ${contenedor}/home/ubuntu/.ssh/authorized_keys --uid 1000 --gid 1000 

        incus exec ${contenedor} --user 1000 --group 1000 -- mkdir -p /home/ubuntu/git
        incus exec ${contenedor} --user 1000 --group 1000 -- git -C /home/ubuntu/git clone https://github.com/miguelinux/dotfiles.git
    ;;
esac
