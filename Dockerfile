
ARG IMG_BASE=ethernitynet/enet-ovs-dpdk:ovs-v2.10.1

FROM $IMG_BASE

COPY utils/*.sh ${SRC_DIR}/utils/
COPY env/*.sh ${SRC_DIR}/env/

RUN . ${SRC_DIR}/app-entrypoint.sh; \
	enet_build

WORKDIR ${SRC_DIR}

#CMD ["./ovs_run.sh"]

COPY runtime/*.sh ${SRC_DIR}/runtime/
