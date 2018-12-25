#!/bin/bash

enet_build() {

	echo "enet_build()"
	exec_tgt "/" "yum -y install numactl-devel"
	dpdk_remote_install
}
