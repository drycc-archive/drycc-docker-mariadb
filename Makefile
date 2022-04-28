# If DRYCC_REGISTRY is not set, try to populate it from legacy DEV_REGISTRY
DRYCC_REGISTRY ?= $(DEV_REGISTRY)
IMAGE_PREFIX ?= drycc-addons
COMPONENT ?= mariadb
SHORT_NAME ?= $(COMPONENT)
PLATFORM ?= linux/amd64,linux/arm64
VERSION ?= 10.8

include versioning.mk

SHELL_SCRIPTS = $(shell find ${VERSION}/debian/ -name '*.sh') $(wildcard *.sh)

DEV_ENV_IMAGE := ${DRYCC_REGISTRY}/drycc/go-dev
DEV_ENV_WORK_DIR := /opt/drycc/go/src/${REPO_PATH}
DEV_ENV_CMD := docker run --rm -v ${CURDIR}:${DEV_ENV_WORK_DIR} -w ${DEV_ENV_WORK_DIR} ${DEV_ENV_IMAGE}

# Test processes used in quick unit testing
TEST_PROCS ?= 4

check-docker:
	@if [ -z $$(which docker) ]; then \
	  echo "Missing \`docker\` client which is required for development"; \
	  exit 2; \
	fi

test: test-style

test-style:
	${DEV_ENV_CMD} shellcheck $(SHELL_SCRIPTS)

build: docker-build

docker-build: check-docker
	docker build ${DOCKER_BUILD_FLAGS} -t ${IMAGE} ${VERSION}/debian
	docker tag ${IMAGE} ${MUTABLE_IMAGE}

docker-buildx: check-docker
	docker buildx build --platform ${PLATFORM} -t ${IMAGE} ${VERSION}/debian --push

clean: check-docker
	docker rmi $(IMAGE)

full-clean: check-docker
	docker images -q $(IMAGE_PREFIX)/$(COMPONENT) | xargs docker rmi -f

.PHONY: build docker-build clean commit-hook full-clean
