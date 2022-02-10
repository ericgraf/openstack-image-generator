FROM k8s.gcr.io/scl-image-builder/cluster-node-image-builder-amd64:v0.1.11

USER root

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get install -y qemu qemu-kvm jq

USER imagebuilder

ENV KUBERNETES_VERSION 1.22.5
ENV PACKER_LOG 1


RUN cat packer/qemu/packer.json | \
    jq '.variables.accelerator = "none"' > \
    tmp && \
    mv tmp packer/qemu/packer.json
RUN cat packer/qemu/packer.json | \
    jq ".variables.kubernetes_semver = \"${KUBERNETES_VERSION}\""  > \
    tmp && \
    mv tmp packer/qemu/packer.json

ENTRYPOINT [ "/usr/bin/make" ]



