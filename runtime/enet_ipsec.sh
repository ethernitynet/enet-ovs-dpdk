#!/bin/bash

enet_ipsec_unique_vlan_by_subnets() {

	local subnet_tx=$1
	local subnet_rx=$2
	local hashval=$(md5sum <<< "${subnet_tx} ${subnet_rx}")
	local hashmod="${hashval:0:3}"
	echo $(( ((16#${hashmod}) % 2048) + 2048 ))
}

enet_ipsec_del_flows_vlan_pop_encrypt() {

	local in_port=$1
	local in_vlan=$2
	local nw_src_trusted=$3
	local nw_dst_protected=$4

	#local in_vlan=$(nic_get_unique_vlan_by_subnets ${trusted_net} ${protected_net})
	local in_vlan_hex=$(printf '0x81000%03x' ${in_vlan})
	set -x
	exec_delete=$(\
		meaCli mea service show edit all | \
		sed -n "s/^${WS}\([0-9][0-9]*\)${WS}${in_port}${WS}${in_vlan_hex}${WS}N${WS}\/${WS}N${WS}transp${WS}NA${WS}0x00000000${WS}N${WS}\/${WS}N${WS}transp${WS}NA${WS}0${WS}NA${WS}Encrypt${WS}\([0-9][0-9]*\)${WS}NONE${WS}${ENET_ENG_ID_VLAN_POP}${WS}NONE${WS}NA.*$/nic_exec service set delete \1; nic_exec IPSec ESP set delete \2;/p"\
		)
	set +x
	eval "${exec_delete}"
	echo "${in_vlan}"
}

enet_ipsec_del_flows_vlan_push_decrypt() {

	local priority=$1
	local in_port=$2
	local tun_remote_ip=$3
	local tun_local_ip=$4
	local out_vlan=$5

	local out_vlan_hex=$(printf '0x81000%03x' ${out_vlan})
	set -x
	exec_delete=$(\
			meaCli mea service show edit all | \
			sed -n "s/^${WS}\([0-9][0-9]*\)${WS}${in_port}${WS}${out_vlan_hex}${WS}N${WS}\/${WS}N${WS}transp${WS}NA${WS}0x00000000${WS}N${WS}\/${WS}N${WS}transp${WS}NA${WS}0${WS}NA${WS}Decrypt${WS}\([0-9][0-9]*\)${WS}NONE${WS}${ENET_ENG_ID_VLAN_PUSH}${WS}NONE${WS}NA.*$/nic_exec service set delete \1; nic_exec IPSec ESP set delete \2;/p"\
			)
	set +x
	eval "${exec_delete}"
	enet_fwd_del_flows_vlan "${ENET_VPORT_IPSEC}" "${out_vlan}"
}

enet_ipsec_add_flow_vlan_pop_encrypt() {

	local priority=$1
	local in_port=$2
	local in_vlan=$3
	local nw_src_trusted=$4
	local nw_dst_protected=$5
	local push_esp_spi=$6
	local auth_algo=$7
	local auth_key=$8
	local cipher_algo=$9
	local cipher_key=${10}
	local tun_local_ip=${11}
	local tun_remote_ip=${12}
	local output=${13}
	local in_vlan_mask=$(printf 'FF%03X' "${in_vlan}")
	local in_vlan_header=$(printf '81000%03X' "${in_vlan}")

	################################
	local in_vlan=$(enet_ipsec_unique_vlan_by_subnets ${nw_src_trusted} ${nw_dst_protected})
	local in_vlan=$(\
	nic_flow_vlan_pop_encrypt_and_fwd_clear \
		${in_port} \
		${output} \
		${nw_src_trusted} \
		${nw_dst_protected})
	################################
	local cipher_profile_id=$(\
	nic_cipher_profile_add \
		${push_esp_spi} \
		${auth_algo} \
		${auth_key} \
		${cipher_algo} \
		${cipher_key})
	################################
	nic_exec_ipsec \
	${cipher_profile_id} \
	service set create \
		${in_port} \
		${in_vlan_mask} ${in_vlan_mask} \
		D.C 0 1 0 1000000000 0 ${ENET_DEFAULT_CBS} 0 0 1 \
		${output} \
		-ra 0 \
		${ENET_FLAG_CLASSIFY_TAGGED} \
		-h ${in_vlan_header} 0 0 0 \
		${ENET_FLAG_IPSEC_TUN_ONLY} \
		${tun_local_ip} ${tun_remote_ip} \
		${ENET_FLAG_ESP_ENCRYPT} ${cipher_profile_id} \
		${ENET_ENG_FLAG_VLAN_POP_ENCRYPT}
	################################
}
