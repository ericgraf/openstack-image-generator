# openstack-image-generator
Goal is to generate openstack images in cluster and upload to glance.


# tekton issues. 

Doesn't support concurrency.
https://github.com/tektoncd/experimental/issues/699


# Step 1
## Setup local kind/tekton 

this sets up kind, tekton and docker risgtry on localhost

```
make setup-kind
make setup-tekton
```

## Setup tekton without kind

```
KUBECONFIG=<kubeconfig> make setup-tekton
```


# Add s3 secret / s3 endpoint / bucket name config

```
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: aws-credentials
type: Opaque
stringData:
  credentials: |-
    [default]
    aws_access_key_id     = { aws_access_key_id }
    aws_secret_access_key = { aws_secret_access_key }
  config: |-
    [default]
  cli-params: |
    --endpoint-url=<url>
  bucket-name: |
    <name>
EOF
```


# Run pipeline to build and publish image

## with kind

```
make deploy-triggers
```

## without kind

```
KUBECONFIG=<kubeconfig> make deploy-triggers
```


# Kind Kubeconfig
## Set kubeconfig

```
KIND_CLUSTER_NAME=tekton-testing
KUBECONFIG_FOLDER=/tmp
export KUBECONFIG=${KUBECONFIG_FOLDER}/${KIND_CLUSTER_NAME}.kubeconfig
```

## create kubeconfig from existing kind cluster

```
KIND_CLUSTER_NAME=tekton-testing
KUBECONFIG_FOLDER=/tmp
kind get kubeconfig --name ${KIND_CLUSTER_NAME} > ${KUBECONFIG_FOLDER}/${KIND_CLUSTER_NAME}.kubeconfig
```


# Cleanup


## Cleanup local kind setup

```
make cleanup-kind
```

---


# Build image locally without tekton

- Change k8s variable version in top of makefile
- Image will be built in ./output/ubuntu-2004-kube-vXXXX folder

## with kvm support

```
make buildimage
```

## without kvm support

```
make buildimage-no-kvm
```

# Create sha256sum

```
cd ./output/ubuntu-2004-kube-vXXXX
sha256sum ubuntu-2004-kube-vXXXX > ubuntu-2004-kube-vXXXX.sha256sums
```

# Manually upload image

```
aws configure
alias awscli='aws --profile=<profile name used above> --endpoint="<endpoint url>'
```

# if bucket doesn't already exist

```
awscli s3 mb s3://bucket_name/
```

# upload image

```
awscli s3 cp ./output/ubuntu-2004-kube-vXXXX s3://bucket_name/
```

