SHELL:=/bin/sh
.PHONY: all format vet test build build-nomod clean docker docker-push docker-test

export GO111MODULE=on
export GOPROXY=https://goproxy.io

pkgs	= $(shell go list ./... | grep -v vendor/)

# path related
MKFILE_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
MKFILE_DIR  := $(dir $(MKFILE_PATH))

DOCKER_IMAGE_NAME ?= feiyu563/prometheus-alert

BRANCH      ?= $(shell git rev-parse --abbrev-ref HEAD)
BUILDDATE   ?= $(shell date -I'seconds')
BUILDUSER   ?= $(shell whoami)@$(shell hostname)
REVISION    ?= $(shell git rev-parse HEAD)
TAG_VERSION ?= $(shell git describe --tags --abbrev=0)

VERSION_LDFLAGS := \
	-X main.Version=$(TAG_VERSION) \
	-X main.Revision=$(REVISION) \
	-X main.BuildUser=$(BUILDUSER) \
	-X main.BuildDate=$(BUILDDATE)

# go source files, ignore vendor directory
SOURCE = $(shell find ${MKFILE_DIR} -path "${MKFILE_DIR}vendor" -prune -o -type f -name "*.go" -print)
TARGET = ${MKFILE_DIR}/PrometheusAlert

all: ${TARGET}

${TARGET}: ${SOURCE}
	@echo ">> building code"
	@if [ -z "$$DOCKER_BUILD" ]; then \
		echo ">> running go mod tidy & vendor"; \
		go mod tidy; \
		go mod vendor; \
	else \
		echo ">> DOCKER_BUILD set, skip go mod tidy/vendor"; \
	fi
	GOMAXPROCS=1 go build -ldflags "$(VERSION_LDFLAGS)" -o ${TARGET}

build-nomod:
	@echo ">> building code (no go mod tidy/vendor)"
	GOMAXPROCS=1 go build -ldflags "$(VERSION_LDFLAGS)" -o ${TARGET}

format:
	@echo ">> formatting code"
	go fmt $(pkgs)

vet:
	@echo ">> vetting code"
	go vet $(pkgs)

test:
	@echo ">> running short tests"
	go test -short $(pkgs)

build: all

clean:
	@echo ">> cleaning build"
	rm  ${TARGET}

docker:
	@echo ">> building docker image"
	docker build -t "$(DOCKER_IMAGE_NAME):$(TAG_VERSION)" .
	docker tag "$(DOCKER_IMAGE_NAME):$(TAG_VERSION)" "$(DOCKER_IMAGE_NAME):latest"

docker-push:
	@echo ">> pushing docker image"
	docker push "$(DOCKER_IMAGE_NAME):$(TAG_VERSION)"
	docker push "$(DOCKER_IMAGE_NAME):latest"

docker-test:
	@echo ">> testing docker image and PrometheusAlert's health"
	cmd/test_image.sh "$(DOCKER_IMAGE_NAME):$(TAG_VERSION)" 8080
