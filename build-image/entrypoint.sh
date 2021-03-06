#!/usr/bin/env bash

    
cat  packer/config/kubernetes.json | \
    jq ".kubernetes_semver = \"v${KUBERNETES_VERSION}\""  > \
    tmp && \
    mv tmp packer/config/kubernetes.json
    
cat packer/config/kubernetes.json | \
    jq ".kubernetes_deb_version = \"${KUBERNETES_VERSION}-00\""  > \
    tmp && \
    mv tmp packer/config/kubernetes.json
    
cat packer/config/kubernetes.json | \
    jq ".kubernetes_series = \"v${KUBERNETES_SERIES}\""  > \
    tmp && \
    mv tmp packer/config/kubernetes.json

cat packer/qemu/packer.json | \
    jq ".variables.accelerator = \"${ACCELERATOR}\"" > \
    tmp && \
    mv tmp packer/qemu/packer.json

cat packer/raw/packer.json | \
    jq ".variables.accelerator = \"${ACCELERATOR}\"" > \
    tmp && \
    mv tmp packer/raw/packer.json



exec "$@"
