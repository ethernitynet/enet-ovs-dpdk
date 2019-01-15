#!/bin/bash

enet_ovs_add_nic_br() {

	local nic_br=$1
	
	enet_exec "service set delete all"
	enet_exec "action set delete all"
	enet_exec "forwarder delete all"
	enet_exec "port ingress set all -a 1 -c 0"
	enet_exec "port egress set all -a 1 -c 0"
}

enet_ovs_attach_nic_dpdk_port() {

	local ovs_br=$1
	local port_name=$2
	local pci_addr=$3
	
	ovs_dpdk add-dpdk-port "${ovs_br}" "${port_name}" "${pci_addr}"
}

enet_ovs_attach_nic_port() {

	local ovs_br=$1
	local port_name=$2
	
	ovs_dpdk add-port "${ovs_br}" "${port_name}"
}

enet_fwd_del_flows_vlan_push() {

	local priority=$1
	local in_port=$2
	local out_vlan=$3
	local out_port=$4

	local out_vlan_hex=$(printf '0ff%03x' ${out_vlan})
	set -x
	exec_delete=$(\
			meaCli mea service show entry all | \
			sed -n "s/^EXT${WS}\(.*\)${WS}${port}${WS}1${WS}0${WS}0x${out_vlan_hex}${WS}NA${WS}NA${WS}NA${WS}DC7${WS}NA${WS}noIP${WS}0.*$/meaCli mea service set delete \1;/p"\
			)
	set +x
	exec_tgt "/" "${exec_delete}"
}

enet_fwd_del_flows_vlan_pop() {

	local priority=$1
	local in_port=$2
	local in_vlan=$3
	local out_port=$4

	local in_vlan_hex=$(printf '0ff%03x' ${in_vlan})
	set -x
	exec_delete=$(\
			meaCli mea service show entry all | \
			sed -n "s/^EXT${WS}\(.*\)${WS}${port}${WS}1${WS}0${WS}0x${in_vlan_hex}${WS}NA${WS}NA${WS}NA${WS}DC7${WS}NA${WS}noIP${WS}0.*$/meaCli mea service set delete \1;/p"\
			)
	set +x
	exec_tgt "/" "${exec_delete}"
}

enet_fwd_add_flow_vlan_pop() {

	local priority=$1
	local in_port=$2
	local in_vlan=$3
	local out_port=$4
	local in_vlan_mask=$(printf 'FF%03X' "${in_vlan}")

	################################
	#enet_fwd_del_flows_vlan \
	#	${priority} \
	#	${in_port} \
	#	${in_vlan}
	################################
	enet_exec "\
		service set create \
		${in_port} \
		${in_vlan_mask} ${in_vlan_mask} \
		D.C 0 1 0 1000000000 0 ${ENET_DEFAULT_CBS} 0 0 1 \
		${out_port} \
		-ra 0 \
		${ENET_FLAG_CLASSIFY_TAGGED} \
		-h 0 0 0 0 \
		${ENET_ENG_ID_VLAN_POP}"
	################################
}

enet_fwd_add_flow_vlan_push() {

	local priority=$1
	local in_port=$2
	local out_vlan=$3
	local out_port=$4
	local out_vlan_header=$(printf '81000%03X' "${out_vlan}")

	################################
	#enet_fwd_del_flows_vlan \
	#	${priority} \
	#	${in_port} \
	#	${in_vlan}
	################################
	enet_exec "\
		service set create \
		${in_port} \
		FF000 FF000 \
		D.C 0 1 0 1000000000 0 ${ENET_DEFAULT_CBS} 0 0 1 \
		${out_port} \
		-ra 0 \
		-Ed 0 \
		${ENET_FLAG_CLASSIFY_UNTAGGED} \
		-h ${out_vlan_header} 0 0 1 \
		${ENET_ENG_FLAG_VLAN_PUSH}"
	################################
}

enet_ovs_add_flow() {

	local nic_br=$1
	local flow_pattern=$2
	shift 2

	case ${flow_pattern} in
		$ENET_FWD_VLAN_POP_PATTERN)
		enet_fwd_add_flow_vlan_pop $@
		;;
		$ENET_FWD_VLAN_PUSH_PATTERN)
		enet_fwd_add_flow_vlan_push $@
		;;
		*)
		print_log "UNSUPPORTED FLOW PATTERN: ${flow_pattern}"
		;;
	esac
}

enet_ovs_del_flows() {

	local nic_br=$1
	local flow_pattern=$2
	shift 1

	case ${flow_pattern} in
		$ENET_FWD_VLAN_POP_PATTERN)
		enet_fwd_del_flows_vlan_pop $@
		;;
		$ENET_FWD_VLAN_PUSH_PATTERN)
		enet_fwd_del_flows_vlan_push $@
		;;
		*)
		print_log "UNSUPPORTED FLOWS PATTERN: ${flow_pattern}"
		;;
	esac
}

enet_ovs() {

	local cmd=$1
	local nic_br=$2
	shift 2

	case "${cmd} ${nic_br}" in
		"add-nic-br $ENET_NIC_BR")
		enet_ovs_add_nic_br $@
		;;
		"attach-nic-dpdk-port $ENET_NIC_BR")
		enet_ovs_attach_nic_dpdk_port $@
		;;
		"attach-nic-port $ENET_NIC_BR")
		enet_ovs_attach_nic_port $@
		;;
		"add-flow $ENET_NIC_BR")
		enet_ovs_add_flow $@
		;;
		"del-flows $ENET_NIC_BR")
		enet_ovs_del_flows $@
		;;
		*)
		enet_exec $@
		;;
	esac
}
