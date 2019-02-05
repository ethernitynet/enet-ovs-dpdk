#!/bin/bash

ACENIC_ID=${1:-0}
ACENIC_LABEL=${2:-ACENIC1_127}
ACENIC_710_SLOT=${2:-3d:00.0}
IMG_DOMAIN=${3:-local}
OVS_VERSION=${4:-v2.10.1}

docker volume rm $(docker volume ls -qf dangling=true)
#docker network rm $(docker network ls | grep "bridge" | awk '/ / { print $1 }')
docker rmi $(docker images --filter "dangling=true" -q --no-trunc)
docker rmi $(docker images | grep "none" | awk '/ / { print $3 }')
docker rm $(docker ps -qa --no-trunc --filter "status=exited")

DOCKER_INST="enet${ACENIC_ID}-ovs"

case ${IMG_DOMAIN} in
	"hub")
	IMG_TAG=ethernitynet/enet-ovs-dpdk:$OVS_VERSION
	docker pull $IMG_TAG
	;;
	*)
	IMG_TAG=local/enet-ovs-dpdk:$OVS_VERSION
	IMG_BASE=local/ovs-box:$OVS_VERSION
	docker build \
		-t $IMG_TAG \
		--build-arg IMG_BASE=$IMG_BASE \
		./
	;;
esac

docker kill $DOCKER_INST
docker rm $DOCKER_INST
docker run \
	-t \
	-d \
	--rm \
	--net=host \
	--privileged \
	-v /mnt/huge:/mnt/huge \
	--device=/dev/uio0:/dev/uio0 \
	--env ACENIC_ID=$ACENIC_ID \
	--env ACENIC_LABEL=$ACENIC_LABEL \
	--env ACENIC_710_SLOT=$ACENIC_710_SLOT \
	--env DOCKER_INST=$DOCKER_INST \
	--hostname=$DOCKER_INST \
	--name=$DOCKER_INST \
	$IMG_TAG \
	/bin/bash
