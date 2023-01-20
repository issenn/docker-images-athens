# Usage:
# make        # compile all binary
# make clean  # remove ALL binaries and objects

PACKAGE_NAME               ?= athens
# PACKAGE_VERSION            ?= 0.11.0
PACKAGE_VERSION_PREFIX     ?= v
PACKAGE_URL                ?= https://github.com/gomods/athens
PACKAGE_SOURCE_URL         ?= https://github.com/gomods/athens/archive/master.tar.gz
PACKAGE_HEAD_URL           ?= https://github.com/gomods/athens.git
PACKAGE_HEAD               ?= false

# Golang
GO111MODULE                ?= on
GOPROXY                    ?= http://10.0.0.102:3000,https://goproxy.cn,https://proxy.golang.com.cn,https://mirrors.aliyun.com/goproxy/,gosum.io+ce6e7565+AY5qEHUk/qmHc5btzW45JVoENfazw8LielDsaI+lEbq6,direct
GOSUMDB                    ?= off
CGO_ENABLED                ?= 0
BUILD_FLAGS                ?= -v
BUILDPLATFORM              ?= linux/amd64
TARGETOS                   ?= linux
TARGETARCH                 ?= amd64
TARGETVARIANT              ?=

VERSION                    ?= $(PACKAGE_VERSION)
# https://docs.brew.sh/Cask-Cookbook
# VERSION_MAJOR              := $(shell echo $(VERSION) | sed "s/^\([0-9]*\).*/\1/")
VERSION_MAJOR              := $(shell echo $(VERSION) | cut -f1 -d.)
# VERSION_MINOR              := $(shell echo $(VERSION) | sed "s/[0-9]*\.\([0-9]*\).*/\1/")
VERSION_MINOR              := $(shell echo $(VERSION) | cut -f2 -d.)
# VERSION_PATCH              := $(shell echo $(VERSION) | sed "s/[0-9]*\.[0-9]*\.\([0-9]*\).*/\1/")
VERSION_PATCH              := $(shell echo $(VERSION) | cut -f3 -d.)
VERSION_MAJOR_MINOR        := $(VERSION_MAJOR).$(VERSION_MINOR)

# COMMIT                     := $(shell git rev-parse HEAD)

# Docker
DOCKER_VERSION             := $(shell docker --version)

# DOCKER_REGISTRY            ?= quay.io
IMAGE_NAME                 := athens
IMAGE_PREFIX               ?= issenn
IMAGE_TAG                  ?= latest

ifdef DOCKER_REGISTRY
    REPOSITORY             := $(DOCKER_REGISTRY)/$(IMAGE_PREFIX)/$(IMAGE_NAME)
else
    REPOSITORY             := $(IMAGE_PREFIX)/$(IMAGE_NAME)
endif

LABEL                      ?= "Maintainer=Issenn <issenn@issenn.ml>"
PUSH_IMAGE                 ?= false
LATEST                     := latest

PROXY                      ?= socks5://10.0.0.131:10810
NO_PROXY                   ?= localhost,127.0.0.1
USE_PROXY                  ?= false

DOCKER_BUILDKIT            ?= true
BUILDKIT_PROGRESS          ?= auto  # auto / plain

default: all
	@echo 'Run `make options` for a list of all options'

options: help
	@echo
	@echo 'Options:'
	@echo 'DOCKER = $(DOCKER_VERSION)'
    # @echo 'DOCDIR = $(DOCDIR)'
    # @echo 'DESTDIR = $(DESTDIR)'

help:
	@echo 'make:                 Test and compile.'
	@echo 'make clean:           Remove the compiled files'

all: build

build:
    ifeq ($(USE_PROXY), true)
	    env DOCKER_BUILDKIT=$(DOCKER_BUILDKIT) BUILDKIT_PROGRESS=$(BUILDKIT_PROGRESS) \
	        docker build -t $(REPOSITORY):$(IMAGE_TAG) \
	            --label $(LABEL) \
	            --build-arg GO111MODULE="${GO111MODULE}" \
	            --build-arg GOPROXY="${GOPROXY}" \
	            --build-arg GOSUMDB="${GOSUMDB}" \
	            --build-arg CGO_ENABLED="${CGO_ENABLED}" \
	            --build-arg BUILD_FLAGS="${BUILD_FLAGS}" \
	            --build-arg PACKAGE_NAME="$(PACKAGE_NAME)" \
	            --build-arg PACKAGE_VERSION="$(PACKAGE_VERSION)" \
	            --build-arg PACKAGE_VERSION_PREFIX="$(PACKAGE_VERSION_PREFIX)" \
	            --build-arg PACKAGE_HEAD_URL="$(PACKAGE_HEAD_URL)" \
	            --build-arg PACKAGE_HEAD="$(PACKAGE_HEAD)" \
	            --build-arg PACKAGE_URL="$(PACKAGE_URL)" \
	            --build-arg PACKAGE_SOURCE_URL="$(PACKAGE_SOURCE_URL)" \
	            --build-arg HTTP_PROXY="$(PROXY)" \
	            --build-arg HTTPS_PROXY="$(PROXY)" \
	            --build-arg NO_PROXY="$(NO_PROXY)" \
	            -f Dockerfile .
                # --build-arg BUILDPLATFORM=$(BUILDPLATFORM) \
                # --build-arg TARGETOS=$(TARGETOS) \
                # --build-arg TARGETARCH=$(TARGETARCH)
    else
	    env DOCKER_BUILDKIT=$(DOCKER_BUILDKIT) BUILDKIT_PROGRESS=$(BUILDKIT_PROGRESS) \
	        docker build -t $(REPOSITORY):$(IMAGE_TAG) \
	            --label $(LABEL) \
	            --build-arg GO111MODULE="${GO111MODULE}" \
	            --build-arg GOPROXY="${GOPROXY}" \
	            --build-arg GOSUMDB="${GOSUMDB}" \
	            --build-arg CGO_ENABLED="${CGO_ENABLED}" \
	            --build-arg BUILD_FLAGS="${BUILD_FLAGS}" \
	            --build-arg PACKAGE_NAME="$(PACKAGE_NAME)" \
	            --build-arg PACKAGE_VERSION="$(PACKAGE_VERSION)" \
	            --build-arg PACKAGE_VERSION_PREFIX="$(PACKAGE_VERSION_PREFIX)" \
	            --build-arg PACKAGE_HEAD_URL="$(PACKAGE_HEAD_URL)" \
	            --build-arg PACKAGE_HEAD="$(PACKAGE_HEAD)" \
	            --build-arg PACKAGE_URL="$(PACKAGE_URL)" \
	            --build-arg PACKAGE_SOURCE_URL="$(PACKAGE_SOURCE_URL)" \
	            -f Dockerfile .
    endif

version:
	@docker run --rm -it $(REPOSITORY):$(IMAGE_TAG) --version

test:
	@docker run --rm -it $(REPOSITORY):$(IMAGE_TAG)

compile:

clean:
	@echo "Cleaning up..."

.PHONY : clean-docker-cache
clean-docker-cache:
	docker builder prune

.PHONY : default options help all build version test compile clean
