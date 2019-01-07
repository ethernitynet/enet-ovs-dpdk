
ARG IMG_BASE=shrewdthingsltd/ovs-box:v2.10.1

FROM $IMG_BASE

ENV ENET_DIR=${SRC_DIR}/enet

COPY app/ ${SRC_DIR}/
ENV BASH_ENV=${SRC_DIR}/docker-entrypoint.sh

RUN enet_build

COPY runtime/ ${SRC_DIR}/runtime/
ENV BASH_ENV=${SRC_DIR}/app-entrypoint.sh

WORKDIR ${ENET_DIR}

#CMD ["./enet_run.sh"]
