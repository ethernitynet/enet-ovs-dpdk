#!/bin/bash

enet_exec() {

################################
local enet_pattern="meaCli mea %s $@"
[[ ${ACENIC_ID} > 0 ]] && enet_pattern="meaCli -card %d mea $@"
local enet_cmd=$(printf "${enet_pattern}" ${ACENIC_ID})
################################
	exec_tgt '/' "\
		meaCli top;\
		sleep 0.1;\
		eval '${enet_cmd}'"
}

enet_run() {

	exec_tgt "${TGT_ENET_DIR}/AceNic_output" "\
		./AppInit_AceNic"
}

enet_ovs_attach() {

	local ovs_br=$1
	
	if [[ ${ENET_OVS_DATAPLANE} == "userspace" ]]
	then
		ovs_dpdk add-dpdk-br ${ovs_br}
		enet_ovs attach-nic-dpdk-port $ENET_NIC_BR ${ovs_br} $ENET_NIC_INTERFACE $ENET_NIC_PCI
	else
		ovs_dpdk add-br ${ovs_br}
		enet_ovs attach-nic-port $ENET_NIC_BR ${ovs_br} $ENET_NIC_INTERFACE
	fi
	ovs_dpdk set-port-id $ENET_NIC_INTERFACE 127
}

enet_add_vlan_bypass_br() {

	local ovs_br=$1
	
	local inbound_priority=100
	local outbound_priority=200
	enet_ovs add-nic-br $ENET_NIC_BR
	enet_ovs add-flow $ENET_NIC_BR $ENET_FWD_VLAN_PUSH_PATTERN ${inbound_priority} 104 104 $ENET_HOST_PORT
	enet_ovs add-flow $ENET_NIC_BR $ENET_FWD_VLAN_PUSH_PATTERN ${inbound_priority} 105 105 $ENET_HOST_PORT
	enet_ovs add-flow $ENET_NIC_BR $ENET_FWD_VLAN_PUSH_PATTERN ${inbound_priority} 106 106 $ENET_HOST_PORT
	enet_ovs add-flow $ENET_NIC_BR $ENET_FWD_VLAN_PUSH_PATTERN ${inbound_priority} 107 107 $ENET_HOST_PORT
	
	enet_ovs add-flow $ENET_NIC_BR $ENET_FWD_VLAN_POP_PATTERN ${outbound_priority} $ENET_HOST_PORT 104 104
	enet_ovs add-flow $ENET_NIC_BR $ENET_FWD_VLAN_POP_PATTERN ${outbound_priority} $ENET_HOST_PORT 105 105
	enet_ovs add-flow $ENET_NIC_BR $ENET_FWD_VLAN_POP_PATTERN ${outbound_priority} $ENET_HOST_PORT 106 106
	enet_ovs add-flow $ENET_NIC_BR $ENET_FWD_VLAN_POP_PATTERN ${outbound_priority} $ENET_HOST_PORT 107 107
	
	ovs_dpdk add-dpdk-br ${ovs_br}
	enet_ovs attach-nic-port $ENET_NIC_BR ${ovs_br} $ENET_NIC_INTERFACE $ENET_NIC_PCI
}
