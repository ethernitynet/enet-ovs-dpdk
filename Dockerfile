
ARG IMG_BASE=shrewdthingsltd/ovs-box:v2.10.1

FROM $IMG_BASE

COPY app/ ${SRC_DIR}/
ENV BASH_ENV=${SRC_DIR}/docker-entrypoint.sh

RUN enet_build

COPY runtime/ ${SRC_DIR}/runtime/
ENV BASH_ENV=${SRC_DIR}/app-entrypoint.sh

WORKDIR ${SRC_DIR}

#CMD ["./ovs_run.sh"]
