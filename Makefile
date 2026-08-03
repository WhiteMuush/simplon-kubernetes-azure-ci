ACR_NAME    ?= mpetitacr01
REGISTRY    ?= $(ACR_NAME).azurecr.io
IMAGE_NAME  ?= microservices-app
TAG         ?= $(shell git rev-parse --short HEAD)
IMAGE       := $(REGISTRY)/$(IMAGE_NAME):$(TAG)

RESOURCE_GROUP ?= mpetitRG
CLUSTER_NAME   ?= mpetitK8s01
K8S_DIR        ?= k8s

.DEFAULT_GOAL := help

.PHONY: help
help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-16s\033[0m %s\n", $$1, $$2}'

.PHONY: login
login: ## Authenticate Docker against the ACR
	az acr login -n $(ACR_NAME)

.PHONY: build
build: ## Build the container image tagged with the current commit SHA
	docker build -t $(IMAGE) .

.PHONY: push
push: ## Push the image to the ACR
	docker push $(IMAGE)

.PHONY: release
release: login build push ## Login, build and push in one go
	@echo "pushed $(IMAGE)"

.PHONY: tags
tags: ## List the tags available in the registry
	az acr repository show-tags -n $(ACR_NAME) --repository $(IMAGE_NAME) -o table

.PHONY: kubeconfig
kubeconfig: ## Fetch the AKS credentials and switch to that context
	az aks get-credentials -g $(RESOURCE_GROUP) -n $(CLUSTER_NAME) --overwrite-existing
	kubectx $(CLUSTER_NAME)

.PHONY: context
context: ## Show the cluster kubectl currently points at
	@kubectl config current-context
	@kubectl get nodes

.PHONY: deploy
deploy: guard-context ## Apply the manifests with the current image tag
	kubectl apply -f $(K8S_DIR)/
	kubectl set image deployment/api api=$(IMAGE)
	kubectl set image deployment/books books=$(IMAGE)
	kubectl set image deployment/movies movies=$(IMAGE)
	kubectl rollout status deployment/api

.PHONY: status
status: ## Show pods and services
	kubectl get pods,svc -o wide

.PHONY: url
url: ## Print the public URL of the application
	@ip=$$(kubectl get svc api -o jsonpath='{.status.loadBalancer.ingress[0].ip}'); \
	if [ -z "$$ip" ]; then echo "load balancer IP not assigned yet"; else echo "http://$$ip/data"; fi

.PHONY: logs
logs: ## Tail the API logs
	kubectl logs -l app=api --tail=100 -f

.PHONY: guard-context
guard-context:
	@current=$$(kubectl config current-context); \
	if [ "$$current" != "$(CLUSTER_NAME)" ]; then \
		echo "refusing to deploy: current context is '$$current', expected '$(CLUSTER_NAME)'"; \
		echo "run 'make kubeconfig' first"; \
		exit 1; \
	fi

.PHONY: clean
clean: ## Remove the locally built image
	-docker rmi $(IMAGE)
