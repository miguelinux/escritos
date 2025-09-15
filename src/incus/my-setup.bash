#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
#
# SPDX-License-Identifier: GPL-3.0-or-later


my_manager=incus

setup_my_user ()
{
        user_id=$1
        user_home=$2
        proxy_env=""

        if [ -n "$https_proxy" ]
        then
            proxy_env="--env=https_proxy=$https_proxy"
        fi
        $my_manager exec ${contenedor} --user ${user_id} --group ${user_id} -- \
            mkdir -m 700 -p ${user_home}/.ssh
        $my_manager file push incus.key.pub \
            ${contenedor}${user_home}/.ssh/authorized_keys --uid ${user_id} --gid ${user_id}

        $my_manager exec ${contenedor} --user ${user_id} --group ${user_id} -- \
            mkdir -p ${user_home}/git
        $my_manager exec ${contenedor} --user ${user_id} --group ${user_id} $proxy_env -- \
            git -C ${user_home}/git clone https://github.com/miguelinux/dotfiles.git

        if [ -n "$http_proxy" ]
        then
            proxyfile=$(mktemp)
            echo export http_proxy=$http_proxy   >  $proxyfile
            echo export https_proxy=$https_proxy >> $proxyfile
            echo export no_proxy=$no_proxy       >> $proxyfile
            echo "# uppercase variables"         >> $proxyfile
            echo export HTTP_PROXY=$http_proxy   >> $proxyfile
            echo export HTTPS_PROXY=$https_proxy >> $proxyfile
            echo export NO_PROXY=$no_proxy       >> $proxyfile

            $my_manager exec ${contenedor} --user ${user_id} --group ${user_id} -- \
                mkdir -p ${user_home}/.config/shrc
            $my_manager file push $proxyfile \
                ${contenedor}${user_home}/.config/shrc/proxy --uid ${user_id} --gid ${user_id}
            rm $proxyfile
        fi
}

###############################################################################

source /usr/lib/os-release

case $ID in
    debian)
        my_manager=incus
    ;;
    ubuntu)
        my_manager=lxc
    ;;
esac

contenedor=$1

if [ -z "${contenedor}" ]
then
    >&2 echo "Falta nombre del contenedor"
    exit 1
fi

if !  $my_manager ls ${contenedor} | grep --quiet RUNNING
then
    >&2 echo "No se encontro el contenedor: ${contenedor} corriendo"
    exit 2
fi

source <($my_manager exec ${contenedor} cat /etc/os-release)

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
        if [ -n "$http_proxy" ]
        then
            dnf_conf=$(mktemp)
            $my_manager file pull ${contenedor}/etc/dnf/dnf.conf $dnf_conf
            echo "proxy=$http_proxy" >> $dnf_conf
            $my_manager file push $dnf_conf ${contenedor}/etc/dnf/dnf.conf
            rm $dnf_conf
        fi
        $my_manager exec ${contenedor} -- dnf -y update
        $my_manager exec ${contenedor} -- dnf -y install $packages_to_install
        $my_manager exec ${contenedor} -- dnf -y install openssh-server
        $my_manager exec ${contenedor} -- systemctl start sshd
    ;;
    debian| ubuntu)
        if [ -n "$http_proxy" ]
        then
            proxyfile=$(mktemp)
            echo Acquire::http::Proxy \"${http_proxy}\"\; > $proxyfile
            $my_manager file push $proxyfile ${contenedor}/etc/apt/apt.conf.d/proxy.conf
            rm $proxyfile
        fi
        $my_manager exec ${contenedor} -- apt-get -y update
        $my_manager exec ${contenedor} -- apt-get -y upgrade
        $my_manager exec ${contenedor} -- apt-get -y install $packages_to_install
        $my_manager exec ${contenedor} -- apt-get -y install $packages_to_install_too
        $my_manager exec ${contenedor} -- apt-get -y install openssh-server
    ;;
esac

# Create & setup user
case $ID in
    debian | centos)
        $my_manager file push add-user-miguel.sh ${contenedor}/root/add-user-miguel.sh
        $my_manager exec ${contenedor} -- /root/add-user-miguel.sh $UID

        setup_my_user $UID /home/miguel
    ;;
    ubuntu)
        setup_my_user 1000 /home/ubuntu
    ;;
esac
