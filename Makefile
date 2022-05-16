KIND_CLUSTER_NAME?=tekton-testing
KUBECONFIG_FOLDER?=/tmp

export 

buildimage:
		docker build -t capo-image ./build-image
		docker run -it --rm --network="host" \
		--device=/dev/kvm \
		-e KUBERNETES_VERSION=1.21.12 \
		-e KUBERNETES_SERIES=1.21 \
		-e ACCELERATOR=kvm \
		-v `pwd`/output:/home/imagebuilder/output/ \
		-v `pwd`/cache:/home/imagebuilder/packer_cache/ \
		capo-image make build-qemu-ubuntu-2004

buildimage-no-kvm:

		docker build -t capo-image ./build-image
		docker run -it --rm --network="host" \
		-e KUBERNETES_VERSION=1.21.12 \
		-e KUBERNETES_SERIES=1.21 \
		-e ACCELERATOR=none \
		-v `pwd`/output:/home/imagebuilder/output/ \
		-v `pwd`/cache:/home/imagebuilder/packer_cache/ \
		capo-image make build-qemu-ubuntu-2004



setup-tekton:

		# Setup kind
		KUBECONFIG=/tmp/delete-kind-kubeconfig bash ./tekton/create-kind-cluster.sh
		#KUBECONFIG=/tmp/delete-kind-kubeconfig kind create cluster --name ${KIND_CLUSTER_NAME}
		kind get kubeconfig --name ${KIND_CLUSTER_NAME} > ${KUBECONFIG_FOLDER}/${KIND_CLUSTER_NAME}.kubeconfig
		chmod 600 ${KUBECONFIG_FOLDER}/${KIND_CLUSTER_NAME}.kubeconfig
		export KUBECONFIG=${KUBECONFIG_FOLDER}/${KIND_CLUSTER_NAME}.kubeconfig

		# Setup Tekton 

		kubectl --kubeconfig=${KUBECONFIG_FOLDER}/${KIND_CLUSTER_NAME}.kubeconfig \
			apply -f https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml

		# Setup Tekton dependencies

		kubectl --kubeconfig=${KUBECONFIG_FOLDER}/${KIND_CLUSTER_NAME}.kubeconfig \
		  apply -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/git-clone/0.3/git-clone.yaml
		
		kubectl --kubeconfig=${KUBECONFIG_FOLDER}/${KIND_CLUSTER_NAME}.kubeconfig \
		  apply -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/docker-build/0.1/docker-build.yaml

		kubectl --kubeconfig=${KUBECONFIG_FOLDER}/${KIND_CLUSTER_NAME}.kubeconfig \
		  apply -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/aws-cli/0.2/aws-cli.yaml


		# deploy image registry
		#kubectl --kubeconfig=${KUBECONFIG_FOLDER}/${KIND_CLUSTER_NAME}.kubeconfig \
		#	apply -f ./tekton/registry-deployment.yaml

run-task:

		kubectl --kubeconfig=${KUBECONFIG_FOLDER}/${KIND_CLUSTER_NAME}.kubeconfig \
		  apply -f ./tekton/task.yaml

		kubectl --kubeconfig=${KUBECONFIG_FOLDER}/${KIND_CLUSTER_NAME}.kubeconfig \
		  delete -f ./tekton/taskrun.yaml;
		kubectl --kubeconfig=${KUBECONFIG_FOLDER}/${KIND_CLUSTER_NAME}.kubeconfig \
		  apply -f ./tekton/taskrun.yaml

		tkn taskrun logs -f -n default

deploy-pipelines:


		kubectl --kubeconfig=${KUBECONFIG_FOLDER}/${KIND_CLUSTER_NAME}.kubeconfig \
		  apply -f ./tekton/task-build-capo-openstack-image.yaml


		kubectl --kubeconfig=${KUBECONFIG_FOLDER}/${KIND_CLUSTER_NAME}.kubeconfig \
		  apply -f ./tekton/build-and-run-pipeline.yaml

		kubectl --kubeconfig=${KUBECONFIG_FOLDER}/${KIND_CLUSTER_NAME}.kubeconfig \
		  delete -f ./tekton/build-and-run-pipelinerun.yaml;

		kubectl --kubeconfig=${KUBECONFIG_FOLDER}/${KIND_CLUSTER_NAME}.kubeconfig \
		  apply -f ./tekton/build-and-run-pipelinerun.yaml

		tkn pipelinerun logs -f -n default

cleanup:
		kind delete cluster --name ${KIND_CLUSTER_NAME}
		docker rm -f kind-registry

openstackcli:
		echo "test"
		docker build ./openstack-cli -t openstack
		docker run --rm -it \
		-e OS_AUTH_URL=$OS_AUTH_URL \
		-e OS_PROJECT_ID=$OS_PROJECT_ID\
		-e OS_PROJECT_NAME=$OS_PROJECT_NAME \
		-e OS_USER_DOMAIN_NAME=$OS_USER_DOMAIN_NAME \
		-e OS_USERNAME=$OS_USERNAME \
		-e OS_PASSWORD=$OS_PASSWORD \
		-e OS_REGION_NAME=$OS_REGION_NAME \
		-e OS_INTERFACE=$OS_INTERFACE \
		-e OS_IDENTITY_API_VERSION=$OS_IDENTITY_API_VERSION \
		openstack


