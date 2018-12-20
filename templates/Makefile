export DOCKER_ORG ?= ${docker_registry}
export DOCKER_IMAGE ?= $(DOCKER_ORG)/${image_name}
export DOCKER_TAG ?= latest
export DOCKER_IMAGE_NAME ?= $(DOCKER_IMAGE):$(DOCKER_TAG)
export DOCKER_BUILD_FLAGS =
export README_DEPS ?= docs/targets.md docs/terraform.md
export INSTALL_PATH ?= /usr/local/bin
export SCRIPT ?= $(notdir $(DOCKER_IMAGE))

-include $(shell curl -sSL -o .build-harness "https://git.io/build-harness"; echo .build-harness)

## Initialize build-harness, install deps, build docker container, install wrapper script and run shell
all: init deps build install run
	@exit 0

## Install dependencies (if any)
deps:
	@exit 0

## Build docker image
build:
	@make --no-print-directory docker/build

## Push docker image to registry
push:
	docker push $(DOCKER_IMAGE)

## Install wrapper script from geodesic container
install:
	@docker run --rm $(DOCKER_IMAGE_NAME) | sudo -E bash -s $(DOCKER_TAG)

## Start the geodesic shell by calling wrapper script
run:
	$(SCRIPT)
