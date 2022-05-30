#!/bin/sh


TEMP_DIR=$(mktemp -d)


cat << EOF > ${TEMP_DIR}/config.json
{
   "auths": { "http://registry.default.svc.cluster.local:5000": {} }

}
EOF

cat << EOF > ${TEMP_DIR}/kind-config.json
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
containerdConfigPatches:
- |-
  [plugins."io.containerd.grpc.v1.cri".registry.mirrors."registry.default.svc.cluster.local:${reg_port}"]
    endpoint = ["http://localhost:5000"]
nodes:
- role: control-plane
  extraPortMappings:
  - containerPort: 5000
    hostPort: 5000
    listenAddress: "0.0.0.0" # Optional, defaults to "0.0.0.0"
    protocol: tcp # Optional, defaults to tcp
EOF


kind create cluster --config ${TEMP_DIR}/kind-config.json