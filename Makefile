.PHONY : all install_kind_linux install_kind_mac create_kind_cluster setup_aws cleanup install_crossplane_cli

default: all

KIND_VERSION := $(shell kind --version 2>/dev/null)

install_kind_linux : 
ifdef KIND_VERSION
	@echo "Found version $(KIND_VERSION)"
else
	@curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.10.0/kind-linux-amd64
	@chmod +x ./kind
	@mv ./kind /bin/kind
endif

install_kind_mac : 
ifdef KIND_VERSION
	@echo "Found version $(KIND_VERSION)"
else
	@brew install kind
endif

create_kind_cluster :
	@echo "Creating kind cluster"
	@kind create cluster --name crossplane-cluster 
	@kind get kubeconfig --name crossplane-cluster
	@kubectl config set-context kind-crossplane-cluster 

create_kind_cluster_with_ingress :
	@echo "Creating kind cluster"
	@kind create cluster --name crossplane-cluster --config=kind-config.yaml
	@kind get kubeconfig --name crossplane-cluster
	@kubectl config set-context kind-crossplane-cluster 
	@kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml

install_crossplane : 
	@echo "Installing crossplane"
	@kubectl create namespace crossplane-system
	@helm repo add crossplane-stable https://charts.crossplane.io/stable
	@helm repo upate
	@helm install crossplane --namespace crossplane-system crossplane-stable/crossplane
	@kubectl wait deployment.apps/crossplane --namespace crossplane-system --for condition=AVAILABLE=True --timeout 1m

CROSSPLANE_CLI := $(shell kubectl crossplane --version 2>/dev/null)

install_crossplane_cli :
ifdef CROSSPLANE_CLI
	@echo "Crssplane CLI already installed"
else
	@curl -sL https://raw.githubusercontent.com/crossplane/crossplane/release-1.5/install.sh | sh
endif

setup_k8s :
	@echo "Setting up Kubernetes provider for local cluster"
	@kubectl apply -f ./k8s-applications/kubernetes-provider-kind.yaml
	@kubectl wait provider.pkg.crossplane.io/crossplane-provider-kubernetes --for condition=HEALTHY=True --timeout 1m
	@echo "Provider Kubernetes configured"

cleanup :
	@kind delete clusters crossplane-cluster

local_k8s : install_kind_linux create_kind_cluster_with_ingress install_crossplane install_crossplane_cli setup_k8s

