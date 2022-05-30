FROM ubuntu:latest

USER root


USER imagebuilder

ENV KUBERNETES_VERSION 1.21.12
ENV KUBERNETES_SERIES 1.21
ENV ACCELERATOR none
ENV PACKER_LOG 1

COPY entrypoint.sh /

ENTRYPOINT [ "/entrypoint.sh" ]
