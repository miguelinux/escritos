#!/bin/bash
# -*- mode: shell-script; indent-tabs-mode: nil; sh-basic-offset: 4; -*-
# ex: ts=8 sw=4 sts=4 et filetype=sh
#
# SPDX-License-Identifier: GPL-3.0-or-later

linode-cli linodes create \
  --type   g6-nanode-1 \
  --region us-west \
  --label  Debian12 \
  --image  linode/debian12 \
  --root_pass "$(< $HOME/.ssh/linode.root.passwd)" \
  --authorized_keys "$(< $HOME/.ssh/linode.key.pub)"
