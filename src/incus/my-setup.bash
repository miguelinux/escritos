#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
#
# SPDX-License-Identifier: GPL-3.0-or-later

setup_my_user ()
{
        user_id=$1
        user_home=$2
        proxy_env=""

        if [ -n "$https_proxy" ]
        then
            proxy_env="--env=https_proxy=$https_proxy"
        fi
        incus exec ${contenedor} --user ${user_id} --group ${user_id} -- \
            mkdir -m 700 -p ${user_home}/.ssh
        incus file push incus.key.pub \
            ${contenedor}${user_home}/.ssh/authorized_keys --uid ${user_id} --gid ${user_id}

        incus exec ${contenedor} --user ${user_id} --group ${user_id} -- \
            mkdir -p ${user_home}/git
        incus exec ${contenedor} --user ${user_id} --group ${user_id} $proxy_env -- \
            git -C ${user_home}/git clone https://github.com/miguelinux/dotfiles.git

        if [ -n "$http_proxy" ]
        then
            proxyfile=$(mktemp)
            echo export http_proxy=$http_proxy > $proxyfile
            echo export https_proxy=$https_proxy >> $proxyfile

            incus exec ${contenedor} --user ${user_id} --group ${user_id} -- \
                mkdir -p ${user_home}/.config/shrc
            incus file push $proxyfile \
                ${contenedor}${user_home}/.config/shrc/proxy --uid ${user_id} --gid ${user_id}
            rm $proxyfile
        fi
}

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

# Update container
case $ID in
    #fedora)
        #dnf -y update
        #dnf -y install $packages_to_install
        #dnf -y install $packages_to_install_too
    #;;
    centos)
        incus exec ${contenedor} -- dnf -y update
        incus exec ${contenedor} -- dnf -y install $packages_to_install
        incus exec ${contenedor} -- dnf -y install openssh-server
    ;;
    debian| ubuntu)
        if [ -n "$http_proxy" ]
        then
            proxyfile=$(mktemp)
            echo Acquire::http::Proxy \"${http_proxy}\"\; > $proxyfile
            incus file push $proxyfile ${contenedor}/etc/apt/apt.conf.d/proxy.conf
            rm $proxyfile
        fi
        incus exec ${contenedor} -- apt-get -y update
        incus exec ${contenedor} -- apt-get -y upgrade
        incus exec ${contenedor} -- apt-get -y install $packages_to_install
        incus exec ${contenedor} -- apt-get -y install $packages_to_install_too
        incus exec ${contenedor} -- apt-get -y install openssh-server
    ;;
esac

# Create & setup user
case $ID in
    debian | centos)
        incus file push add-user-miguel.sh ${contenedor}/root/add-user-miguel.sh
        incus exec ${contenedor} -- /root/add-user-miguel.sh $UID

        setup_my_user $UID /home/miguel
    ;;
    ubuntu)
        setup_my_user 1000 /home/ubuntu
    ;;
esac
