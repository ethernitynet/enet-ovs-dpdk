#!/bin/bash

export WS="\s\{1,\}"
export ENET_FLAG_CLASSIFY_UNTAGGED="-l2Type 0"
export ENET_FLAG_CLASSIFY_TAGGED="-l2Type 1"

export ENET_ENG_ID_VLAN_POP=3
export ENET_ENG_ID_VLAN_PUSH=1
export ENET_ENG_FLAG_VLAN_POP="-hType ${ENET_ENG_ID_VLAN_POP}"
export ENET_ENG_FLAG_VLAN_PUSH="-hType ${ENET_ENG_ID_VLAN_PUSH}"

export ENET_FWD_VLAN_POP_PATTERN='priority=%d,in_port=%s,dl_vlan=%d,actions=strip_vlan,output:%s'
export ENET_FWD_VLAN_PUSH_PATTERN='priority=%d,in_port=%s,actions=push_vlan:0x8100,mod_vlan_vid:%d,output:%s'
