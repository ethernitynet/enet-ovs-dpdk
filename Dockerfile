
ARG IMG_BASE=ethernitynet/enet-ovs-dpdk:ovs-v2.10.1

FROM $IMG_BASE

COPY app/utils/*.sh ${SRC_DIR}/utils/
COPY app/env/*.sh ${SRC_DIR}/env/
COPY app/entrypoint/*.sh ${SRC_DIR}/

RUN enet_build

COPY app/runtime/*.sh ${SRC_DIR}/runtime/

WORKDIR ${SRC_DIR}

#CMD ["./ovs_run.sh"]
