
## tekton dependencies

https://github.com/tektoncd/catalog/tree/main/

```bash
kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/git-clone/0.3/git-clone.yaml
kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/docker-build/0.1/docker-build.yaml

```

# Add docker registry


```bash
kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/docker-build/0.1/tests/resources.yaml
```




# Image creation steps


## Image creation
### build docker image
### Run build image

## Upload image S3
### build docker image
### upload image


## (Optional) Upload image OpenStack 

### build docker image
### upload image

# Set kubeconfig
KIND_CLUSTER_NAME=tekton-testing
KUBECONFIG_FOLDER=/tmp
export KUBECONFIG=${KUBECONFIG_FOLDER}/${KIND_CLUSTER_NAME}.kubeconfig

