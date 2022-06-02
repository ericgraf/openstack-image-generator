KIND_CLUSTER_NAME?=tekton-testing
KUBECONFIG_FOLDER?=/tmp
#HOST_IP=192.168.122.5
HOST_IP=registry.default.svc.cluster.local
datestring=$(shell date +"%Y-%d-%m-%H-%M-%S") 

export 

info: 
	kubectl --kubeconfig=${KUBECONFIG_FOLDER}/${KIND_CLUSTER_NAME}.kubeconfig \
		run my-shell --rm -i --tty --image curlimages/curl -- curl ${HOST_IP}:5000/v2/admin/image-builder/tags/list
	
	docker exec -it  tekton-testing-control-plane bash
	curl localhost:5000/v2/admin/image-builder/tags/list
	docker run --rm -it localhost:5000/admin/image-builder:latest -- echo "worked" 

	curl ${HOST_IP}:5000/v2/admin/image-builder/tags/list

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
		-e KUBERNETES_VERSION=1.22.10 \
		-e KUBERNETES_SERIES=1.22 \
		-e ACCELERATOR=none \
		-v `pwd`/output:/home/imagebuilder/output/ \
		-v `pwd`/cache:/home/imagebuilder/packer_cache/ \
		capo-image make build-qemu-ubuntu-2004

setup-registry-secret:
	kubectl --kubeconfig=${KUBECONFIG_FOLDER}/${KIND_CLUSTER_NAME}.kubeconfig \
		create secret docker-registry local-registry \
		--docker-server="${HOST_IP}:5000" \
		--docker-username=admin \
		--docker-password=admin

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

		#kubectl --kubeconfig=${KUBECONFIG_FOLDER}/${KIND_CLUSTER_NAME}.kubeconfig \
		#  apply -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/aws-cli/0.2/aws-cli.yaml


		kubectl --kubeconfig=${KUBECONFIG_FOLDER}/${KIND_CLUSTER_NAME}.kubeconfig \
		    create secret docker-registry local-registry \
			--docker-server="${HOST_IP}:5000" \
			--docker-username=admin \
			--docker-password=admin

		kubectl --kubeconfig=${KUBECONFIG_FOLDER}/${KIND_CLUSTER_NAME}.kubeconfig \
		  apply -f ./tekton/sa.yaml
		# deploy image registry
		kubectl --kubeconfig=${KUBECONFIG_FOLDER}/${KIND_CLUSTER_NAME}.kubeconfig \
			apply -f ./tekton/registry-deployment.yaml

deploy-tasks: 

		cat ./tekton/task-build-capo-openstack-image.yaml \
		   | sed "s/{time}/${datestring}/g" | sed "s/{HOST_IP}/${HOST_IP}/g"	 |	kubectl --kubeconfig=${KUBECONFIG_FOLDER}/${KIND_CLUSTER_NAME}.kubeconfig \
		  apply -f -

		cat ./tekton/task-gen-checksum.yaml \
		| sed "s/{time}/${datestring}/g" | sed "s/{HOST_IP}/${HOST_IP}/g"	 |	kubectl --kubeconfig=${KUBECONFIG_FOLDER}/${KIND_CLUSTER_NAME}.kubeconfig \
		  apply -f -
		
		cat ./tekton/task-list-output-files.yaml \
		| sed "s/{time}/${datestring}/g" | sed "s/{HOST_IP}/${HOST_IP}/g"	 |	kubectl --kubeconfig=${KUBECONFIG_FOLDER}/${KIND_CLUSTER_NAME}.kubeconfig \
		  apply -f -

		cat ./tekton/task-gen-example-output.yaml \
		| sed "s/{time}/${datestring}/g" | sed "s/{HOST_IP}/${HOST_IP}/g"	 |	kubectl --kubeconfig=${KUBECONFIG_FOLDER}/${KIND_CLUSTER_NAME}.kubeconfig \
		  apply -f -

		kubectl --kubeconfig=${KUBECONFIG_FOLDER}/${KIND_CLUSTER_NAME}.kubeconfig \
			apply -f ./tekton/task-aws-cli.yaml
		#cat ./tekton/task-aws-cli-upload.yaml \
		#| sed "s/{time}/${datestring}/g" | sed "s/{HOST_IP}/${HOST_IP}/g"	 |	kubectl --kubeconfig=${KUBECONFIG_FOLDER}/${KIND_CLUSTER_NAME}.kubeconfig \
		#  apply -f -



taskrun-s3: deploy-tasks

		cat ./tekton/taskrun-s3-upload.yaml | sed "s/{time}/${datestring}/g" | sed "s/{HOST_IP}/${HOST_IP}/g"	 |	kubectl --kubeconfig=${KUBECONFIG_FOLDER}/${KIND_CLUSTER_NAME}.kubeconfig \
		  apply -f -

		KUBECONFIG=${KUBECONFIG_FOLDER}/${KIND_CLUSTER_NAME}.kubeconfig tkn taskrun logs -f -n default

run-pipeline-test: deploy-tasks

		cat ./tekton/pipelinerun-test.yaml | sed "s/{time}/${datestring}/g" | sed "s/{HOST_IP}/${HOST_IP}/g"	 |	kubectl --kubeconfig=${KUBECONFIG_FOLDER}/${KIND_CLUSTER_NAME}.kubeconfig \
		  apply -f -

		KUBECONFIG=${KUBECONFIG_FOLDER}/${KIND_CLUSTER_NAME}.kubeconfig tkn pipelinerun logs -f -n default

cleanup-runs:

	kubectl --kubeconfig=${KUBECONFIG_FOLDER}/${KIND_CLUSTER_NAME}.kubeconfig \
    	delete pod,taskrun,pipeline,pipelineruns,pvc --all

build-openstack-image: deploy-tasks

		cat ./tekton/taskrun-build-openstack-image.yaml \
		| sed "s/{time}/${datestring}/g" | sed "s/{HOST_IP}/${HOST_IP}/g" |	kubectl --kubeconfig=${KUBECONFIG_FOLDER}/${KIND_CLUSTER_NAME}.kubeconfig \
		  apply -f -

deploy-pipelines: deploy-tasks

		cat ./tekton/build-and-run-pipelinerun.yaml \
		| sed "s/{time}/${datestring}/g" | sed "s/{HOST_IP}/${HOST_IP}/g"	 |	kubectl --kubeconfig=${KUBECONFIG_FOLDER}/${KIND_CLUSTER_NAME}.kubeconfig \
		  apply -f -

		KUBECONFIG=${KUBECONFIG_FOLDER}/${KIND_CLUSTER_NAME}.kubeconfig tkn pipelinerun logs -f -n default

cleanup:
		kind delete cluster --name ${KIND_CLUSTER_NAME}
		#docker rm -f kind-registry


cleanup-jobs:
		kubectl --kubeconfig=${KUBECONFIG_FOLDER}/${KIND_CLUSTER_NAME}.kubeconfig \
		 delete taskruns --all
		kubectl --kubeconfig=${KUBECONFIG_FOLDER}/${KIND_CLUSTER_NAME}.kubeconfig \
		 delete pipelineruns --all
		kubectl --kubeconfig=${KUBECONFIG_FOLDER}/${KIND_CLUSTER_NAME}.kubeconfig \
		 delete pvc --all



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


