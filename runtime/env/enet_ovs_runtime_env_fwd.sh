#!/bin/bash

export WS='\s\{1,\}'
export NUM='[0-9][0-9]*'
export MAC='[0-9A-Fa-f\:][0-9A-Fa-f\:]*'
export ENET_FLAG_CLASSIFY_UNTAGGED="-l2Type 0"
export ENET_FLAG_CLASSIFY_TAGGED="-l2Type 1"

export ENET_ENG_ID_VLAN_POP=3
export ENET_ENG_ID_VLAN_PUSH=1
export ENET_ENG_FLAG_VLAN_POP="-hType ${ENET_ENG_ID_VLAN_POP}"
export ENET_ENG_FLAG_VLAN_PUSH="-hType ${ENET_ENG_ID_VLAN_PUSH}"

export ENET_FWD_VLAN_POP_PATTERN='priority=%d,in_port=%s,dl_vlan=%d,actions=strip_vlan,output:%s'
export ENET_FWD_VLAN_PUSH_PATTERN='priority=%d,in_port=%s,actions=push_vlan:0x8100,mod_vlan_vid:%d,output:%s'

export OVS_FLOW_PORT_SUBNET_PAIR_SPEC='in_port=%d,ip,nw_src=%s,nw_dst=%s'
export OVS_FLOW_PORT_SUBNET_PAIR_VLAN_SWAP='priority=%d,in_port=%d,dl_vlan=%d,ip,nw_src=%s,nw_dst=%s,actions=mod_vlan_vid:%d,goto_table:%d'
export OVS_FLOW_PORT_SUBNET_PAIR_L3FWD_VLAN_SWAP='priority=%d,in_port=%d,dl_vlan=%d,ip,nw_src=%s,nw_dst=%s,actions=mod_vlan_vid:%d,mod_dl_src=%s,mod_dl_dst=%s,dec_ttl,output:in_port'

export OVS_FLOW_PORT_ARP_SUBNET_PAIR_DO_L2FWD='priority=%d,in_port=%d,dl_vlan=%d,dl_type=0x0806,nw_src=%s,nw_dst=%s,output:%d'
export OVS_FLOW_PORT_SMAC_ARP_SUBNET_PAIR_DO_SET_DMAC_L2FWD='priority=%d,in_port=%d,dl_src=%s,dl_type=0x0806,nw_src=%s,nw_dst=%s,actions=push_vlan:0x8100,mod_vlan_vid=%d,output:%d'

export OVS_FLOW_PORT_SMAC_DO_PUSH_VLAN='priority=%d,in_port=%d,dl_src=%s,actions=push_vlan:0x8100,mod_vlan_vid=%d,output:%d'
export OVS_FLOW_PORT_DMAC_VLAN_DO_POP_VLAN='priority=%d,in_port=%d,dl_dst=%s,dl_vlan=%d,actions=strip_vlan,output:%d'
