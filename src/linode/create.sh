#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
#
# SPDX-License-Identifier: GPL-3.0-or-later
#
#L_LABEL=Debian12
#L_IMAGE=linode/debian12 

L_LABEL=Ubuntu2204LTS
L_IMAGE=linode/ubuntu22.04

linode-cli linodes create \
  --type   g6-nanode-1 \
  --region us-west \
  --label  ${L_LABEL} \
  --image  ${L_IMAGE} \
  --root_pass "$(< $HOME/.ssh/linode.root.passwd)" \
  --authorized_keys "$(< $HOME/.ssh/linode.key.pub)"
