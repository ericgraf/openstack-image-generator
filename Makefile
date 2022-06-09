KIND_CLUSTER_NAME?=tekton-testing
KUBECONFIG_FOLDER?=/tmp
#HOST_IP=192.168.122.5
HOST_IP=registry.default.svc.cluster.local
KUBECONFIG?=${KUBECONFIG_FOLDER}/${KIND_CLUSTER_NAME}.kubeconfig
datestring=$(shell date +"%Y-%d-%m-%H-%M-%S")-${K8S_VERSION}
GIT_REPO=$(shell  git config --get remote.origin.url)
export 


buildimage:

		sudo chmod 777 /dev/kvm

		docker build -t capo-image ./build-image

		docker run -it --rm --network="host" \
		--device=/dev/kvm \
		-e KUBERNETES_VERSION=${K8S_VERSION} \
		-e ACCELERATOR=kvm \
		-v `pwd`/output:/home/imagebuilder/output/ \
		-v `pwd`/cache:/home/imagebuilder/packer_cache/ \
		capo-image make build-qemu-ubuntu-2004

buildimage-no-kvm:

		docker build -t capo-image ./build-image
		docker run -it --rm --network="host" \
		-e KUBERNETES_VERSION=${K8S_VERSION} \
		-e ACCELERATOR=none \
		-v `pwd`/output:/home/imagebuilder/output/ \
		-v `pwd`/cache:/home/imagebuilder/packer_cache/ \
		capo-image make build-qemu-ubuntu-2004

setup-registry-secret:
	kubectl --kubeconfig=${KUBECONFIG} \
		create secret docker-registry local-registry \
		--docker-server="${HOST_IP}:5000" \
		--docker-username=admin \
		--docker-password=admin

install-tekton-dashboard:
	kubectl --kubeconfig=${KUBECONFIG} \
	  apply -f https://storage.googleapis.com/tekton-releases/dashboard/latest/tekton-dashboard-release.yaml

	kubectl --kubeconfig=${KUBECONFIG} \
	  port-forward -n tekton-pipelines service/tekton-dashboard 9097:9097 &

	#xdg-open http://localhost:9097
	#x-www-browser http://localhost:9097

setup-kind:
	#Setup kind
	KUBECONFIG=/tmp/delete-kind-kubeconfig bash ./tekton/create-kind-cluster.sh
	#KUBECONFIG=/tmp/delete-kind-kubeconfig kind create cluster --name ${KIND_CLUSTER_NAME}
	kind get kubeconfig --name ${KIND_CLUSTER_NAME} > ${KUBECONFIG}
	chmod 600 ${KUBECONFIG}
	export KUBECONFIG=${KUBECONFIG}

setup-tekton: setup-registry-secret

	# Setup Tekton 
	kubectl --kubeconfig=${KUBECONFIG} \
		apply -f https://storage.googleapis.com/tekton-releases/pipeline/latest/release.yaml

	# Setup Tekton dependencies
	kubectl --kubeconfig=${KUBECONFIG} \
		apply -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/git-clone/0.3/git-clone.yaml
	
	kubectl --kubeconfig=${KUBECONFIG} \
		apply -f https://raw.githubusercontent.com/tektoncd/catalog/main/task/docker-build/0.1/docker-build.yaml

	kubectl --kubeconfig=${KUBECONFIG} \
		apply -f https://storage.googleapis.com/tekton-releases/triggers/latest/release.yaml
	kubectl --kubeconfig=${KUBECONFIG} \
		apply -f https://storage.googleapis.com/tekton-releases/triggers/latest/interceptors.yaml

	# Deploy image registry
	kubectl --kubeconfig=${KUBECONFIG} \
		apply -f ./tekton/registry-deployment.yaml

cleanup-kind:
	kind delete cluster --name ${KIND_CLUSTER_NAME}
	#docker rm -f kind-registry


############################
# Triggers
###############################

cleanup-triggers:

	# k8s detect cronjob
	cat ./tekton/pipeline-cron-detect-k8s-versions.yaml | \
		sed "s/<TIME>/${datestring}/g" | \
		sed "s/<HOST_IP>/${HOST_IP}/g"	 |	\
		kubectl --kubeconfig=${KUBECONFIG} \
		delete -f -

	cat ./tekton/build-k8s.yaml | \
		sed "s/<TIME>/${datestring}/g" | \
		sed "s/<HOST_IP>/${HOST_IP}/g"	 |	\
		sed "s/<GIT_REPO>/${GIT_REPO}/g"	 |\
		kubectl --kubeconfig=${KUBECONFIG} \
		delete -f -

	kubectl --kubeconfig=${KUBECONFIG} \
	 get pipelineruns | grep k8s-build | awk -F ' ' '{print "kubectl delete pipelineruns "$1}'
	kubectl --kubeconfig=${KUBECONFIG} \
	 get pipelineruns | grep k8s-detect | awk -F ' ' '{print "kubectl delete pipelineruns "$1}' | xargs -0 sh -c

deploy-triggers:

	# k8s detect cronjob
	cat ./tekton/detect-k8s-versions.yaml | \
		  sed "s/<TIME>/${datestring}/g" | \
		  sed "s/<HOST_IP>/${HOST_IP}/g"	 |	\
		  kubectl --kubeconfig=${KUBECONFIG} \
		  apply -f -

	cat ./tekton/build-k8s.yaml | \
		  sed "s/<TIME>/${datestring}/g" | \
		  sed "s/<HOST_IP>/${HOST_IP}/g"	 |	\
		  kubectl --kubeconfig=${KUBECONFIG} \
		  apply -f -
	
	KUBECONFIG=${KUBECONFIG} tkn pipelinerun logs -f -n default


test-trigger: deploy-triggers
		kubectl --kubeconfig=${KUBECONFIG} \
		run my-shell --rm -i --tty --image curlimages/curl -- \
		curl -X POST \
		http://localhost:8099 \
		-H 'Content-Type: application/json' \
		-d '{ \
			"k8s":\
			{\
				"version": "1.24.1"\
			}\
		}'