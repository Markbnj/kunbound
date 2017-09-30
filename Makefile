default: help

IMAGES_REPO ?= markbnj
IMAGE_NAME ?= kunbound
IMAGE_TAG ?= latest
TEST_HOST ?= google.com
HELM_RELEASE ?= kunbound
KUBE_CONTEXT ?= $(shell kubectl config current-context)
DRY_RUN := --debug --dry-run
NO_CACHE :=
VALUES ?=
VALUES_ARG :=
CLUSTER_IP4_CIDR ?=

.PHONY: no-cache
no-cache:
	$(eval NO_CACHE := --no-cache)
	@:

.PHONY: image
image:
	docker build $(NO_CACHE) --rm=true --force-rm=true --tag=$(IMAGE_NAME):$(IMAGE_TAG) .

.PHONY: test
test:
	docker run -d --name $(IMAGE_NAME)-test -p 8053:53/udp $(IMAGE_NAME):$(IMAGE_TAG)
	dig @localhost -p 8053 $(TEST_HOST)
	docker rm -f $(IMAGE_NAME)-test

.PHONY: build
build: image test

.PHONY: rebuild
rebuild: no-cache image test

.PHONY: push
push:
	docker tag $(IMAGE_NAME):$(IMAGE_TAG) $(IMAGES_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)
	docker push $(IMAGES_REPO)/$(IMAGE_NAME):$(IMAGE_TAG)

.PHONY: apply
apply:
	$(eval DRY_RUN := )
	@:

.PHONY: release
release:
	@if [ ! -z "$(VALUES)" ]; then \
		VALUES_ARG='--values=$(VALUES)'; \
	fi; \
	cd kunbound && \
	helm upgrade --install $(HELM_RELEASE) . \
		--kube-context $(KUBE_CONTEXT) \
		--set image=$(IMAGES_REPO)/$(IMAGE_NAME):$(IMAGE_TAG) \
		--set clusterIpv4Cidr=$(CLUSTER_IP4_CIDR) \
		$${VALUES_ARG} $(DRY_RUN); \
	cd ..

.PHONY: all
all: build push release

.PHONY: help
help:
	@echo "Build the kunbound image and install the helm chart"
	@echo
	@echo "Usage: make TARGETS VARS"
	@echo
	@echo "The following TARGETS are supportedL"
	@echo
	@echo "image: build the docker image locally"
	@echo "test: test the docker image"
	@echo "no-cache: disable docker layer caching"
	@echo "build: runs image + test"
	@echo "rebuild: runs no-cache + image + test"
	@echo "push: push the image to a repo"
	@echo "release: install/upgrade the chart (dry-run)"
	@echo "apply: use before release to apply changes"
	@echo "all: runs build + push + release"
	@echo "help: display this help"
	@echo
	@echo "The following VARS are supportedL"
	@echo
	@echo "IMAGES_REPO: repository name to push image to"
	@echo "IMAGE_NAME: override default image name"
	@echo "IMAGE_TAG: override default image tag"
	@echo "TEST_HOST: override the default DNS test host"
	@echo "HELM_RELEASE: override the default release name"
	@echo "KUBE_CONTEXT: override the current kube context"
	@echo "VALUES: specify a values file to include"
	@echo "CLUSTER_IP4_CIDR: address range to allow"
