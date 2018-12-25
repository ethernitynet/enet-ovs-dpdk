#!/bin/bash

enet_exec() {

	echo "$(\
	exec_tgt '/' '\
		meaCli top;\
		sleep 0.1;\
		meaCli mea $@'\
		)"
}

enet_ovs_add_nic_br() {

	local nic_br=$1
	
	enet_exec "service set delete all"
	print_log "enet-ovs add-nic-br ${nic_br}"
}

enet_ovs_attach_nic_br() {

	local nic_br=$1
	local ovs_br=$2
	local port_name=$3
	local pci_addr=$4
	
	ovs_dpdk_add_dpdk_port "${ovs_br}" "${port_name}" "${pci_addr}"
}

enet_fwd_del_flows_vlan() {

	local priority=$1
	local port=$2
	local vlan=$3

	local in_vlan_hex=$(printf "0ff%03x" ${vlan})
	set -x
	exec_delete=$(\
			meaCli mea service show entry all | \
			sed -n "s/^EXT${WS}\(.*\)${WS}${port}${WS}1${WS}0${WS}0x${in_vlan_hex}${WS}NA${WS}NA${WS}NA${WS}DC7${WS}NA${WS}noIP${WS}0.*$/meaCli mea service set delete \1;/p"\
			)
	set +x
	exec_tgt "/" "${exec_delete}"
}

enet_fwd_add_flow_vlan_pop() {

	local in_port=$1
	local in_vlan=$2
	local out_port=$3
	local in_vlan_mask=$(printf 'FF%03X' "${in_vlan}")

	################################
	#enet_fwd_del_flows_vlan \
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

	local in_port=$1
	local out_vlan=$2
	local out_port=$3
	local out_vlan_header=$(printf '81000%03X' "${out_vlan}")

	################################
	#enet_ovs_del_flows_vlan \
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

	local ovs_br=$1
	local flow_pattern=$2
	shift 2

	case ${flow_pattern} in
		"priority=%d,in_port=%s,dl_vlan=%d,actions=strip_vlan,output:%s")
		enet_fwd_add_flow_vlan_pop $@
		;;
		"priority=%d,in_port=%s,actions=push_vlan:0x8100,mod_vlan_vid=%d,output:%s")
		enet_fwd_add_flow_vlan_push $@
		;;
		*)
		print_log "UNSUPPORTED FLOW PATTERN: ${flow_pattern}"
		;;
	esac
}

enet_ovs_del_flows() {

	local flow_pattern=$1
	shift 1

	case ${flow_pattern} in
		"priority=%d,in_port=%s,dl_vlan=%d,actions=strip_vlan,output:%s")
		enet_fwd_del_flows_vlan $@
		;;
		"priority=%d,in_port=%s,actions=push_vlan,output:%s")
		enet_fwd_del_flows_vlan $@
		;;
		*)
		print_log "UNSUPPORTED FLOWS PATTERN: ${flow_pattern}"
		;;
	esac
}

enet_ovs() {

	local cmd=$1
	local nic_br=$2
	shift

	case "${cmd} ${nic_br}" in
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
