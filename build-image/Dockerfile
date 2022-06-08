FROM k8s.gcr.io/scl-image-builder/cluster-node-image-builder-amd64:v0.1.11

USER root

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get install -y qemu qemu-kvm jq

USER imagebuilder

ENV KUBERNETES_VERSION 1.21.12
ENV ACCELERATOR none
ENV PACKER_LOG 1
ENV CPUS 4
ENV MEMORY 4096

COPY entrypoint.sh /

ENTRYPOINT [ "/entrypoint.sh" ]
