# CI: build the image and push it to the ACR. Nothing else.
# Configuration comes from .env locally, from CI/CD variables in the pipeline.

-include .env
export

IMAGE_NAME ?= microservices-app
TAG        ?= $(shell git rev-parse --short HEAD)
REGISTRY   := $(ACR_NAME).azurecr.io
IMAGE      := $(REGISTRY)/$(IMAGE_NAME):$(TAG)

.DEFAULT_GOAL := help

.PHONY: help
help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-10s\033[0m %s\n", $$1, $$2}'

.PHONY: guard-env
guard-env:
	@test -n "$(ACR_NAME)" || { \
		echo "ACR_NAME is not set."; \
		echo "locally: cp .env.example .env and fill it in"; \
		echo "in CI:   declare it as a CI/CD variable"; \
		exit 1; }

.PHONY: login
login: guard-env ## Authenticate Docker against the ACR
	az acr login -n $(ACR_NAME)

.PHONY: build
build: guard-env ## Build the image tagged with the current commit SHA
	docker build -t $(IMAGE) .

.PHONY: push
push: guard-env ## Push the image to the ACR
	docker push $(IMAGE)

.PHONY: release
release: login build push ## Login, build and push
	@echo "pushed $(IMAGE)"

.PHONY: tags
tags: guard-env ## List the tags available in the registry
	az acr repository show-tags -n $(ACR_NAME) --repository $(IMAGE_NAME) -o table
