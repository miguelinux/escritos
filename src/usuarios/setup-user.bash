#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
#
# SPDX-License-Identifier: GPL-3.0-or-later

test -e /etc/os-release && os_release='/etc/os-release' || os_release='/usr/lib/os-release'
source "${os_release}"

packages_to_install="git git-lfs tmux vim rsync curl"
packages_to_install_too="stow connect-proxy"

case $ID in
    fedora)
        sudo dnf -y update
        sudo dnf -y install $packages_to_install
        sudo dnf -y install $packages_to_install_too
    ;;
    centos)
        sudo dnf -y update
        sudo dnf -y install $packages_to_install
    ;;
    debian|ubuntu)
        sudo apt-get -y update
        sudo apt-get -y upgrade
        sudo apt-get -y install $packages_to_install
        sudo apt-get -y install $packages_to_install_too
    ;;
esac

mkdir -p $HOME/git

if [ ! -d $HOME/git/dotfiles ]
then
    git -C $HOME/git clone https://github.com/miguelinux/dotfiles.git
fi

cd $HOME/git/dotfiles
bash setup.sh
cd -

echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJJNfnjrMP6e1F71DzmKd30pw6BoVi+7eWFwuLQQA4Cs first-key_2025" > $HOME/.ssh/authorized_keys
