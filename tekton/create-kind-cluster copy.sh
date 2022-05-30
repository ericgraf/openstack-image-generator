#!/bin/sh

reg_name=kind-registry
reg_port=5000
if [ "$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)" != 'true' ]; then
  docker run \
    -d --restart=always -p "${reg_port}:5000" --name "${reg_name}" \
    registry:2
fi


TEMP_DIR=$(mktemp -d)


cat << EOF > ${TEMP_DIR}/config.json
{
   "auths": { "http://192.168.122.5:5000": {} }

}
EOF

cat << EOF > ${TEMP_DIR}/kind-config.json
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."192.168.122.5:${reg_port}"]
    endpoint = ["http://192.168.122.5:5000"]
EOF


kind create cluster --config ${TEMP_DIR}/kind-config.json