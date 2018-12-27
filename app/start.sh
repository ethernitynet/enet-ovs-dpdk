#!/bin/bash

OVS_IMG=${1:-local}
OVS_VERSION=${3:-v2.10.1}

docker volume rm $(docker volume ls -qf dangling=true)
#docker network rm $(docker network ls | grep "bridge" | awk '/ / { print $1 }')
docker rmi $(docker images --filter "dangling=true" -q --no-trunc)
docker rmi $(docker images | grep "none" | awk '/ / { print $3 }')
docker rm $(docker ps -qa --no-trunc --filter "status=exited")

case ${OVS_IMG} in
	"hub")
	OVS_IMG=ethernitynet/enet-ovs-dpdk:ovs-$OVS_VERSION
	docker pull $OVS_IMG
	;;
	*)
	IMG_BASE=local/docker-ovs-dpdk:ovs-$OVS_VERSION
	OVS_IMG=local/enet-ovs-dpdk:ovs-$OVS_VERSION
	docker build \
		-t $OVS_IMG \
		--build-arg IMG_BASE=$IMG_BASE \
		./
	;;
esac

docker run \
	-ti \
	--net=host \
	--privileged \
	-v /mnt/huge:/mnt/huge \
	--device=/dev/uio0:/dev/uio0 \
	$OVS_IMG \
	/bin/bash
