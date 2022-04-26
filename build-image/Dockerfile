FROM k8s.gcr.io/scl-image-builder/cluster-node-image-builder-amd64:v0.1.11

USER root

ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get install -y qemu qemu-kvm jq

USER imagebuilder

ENV KUBERNETES_VERSION 1.21.9
ENV KUBERNETES_SERIES 1.21
ENv ACCELERATOR none
ENV PACKER_LOG 1

COPY entrypoint.sh /

ENTRYPOINT [ "/entrypoint.sh" ]



