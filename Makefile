CONTAINER_NAME=$(AWS_CONTAINER)
ECR_REPO=$(AWS_ACCOUNT).dkr.ecr.$(AWS_REGION).amazonaws.com
TAG:=$(shell date +"%Y%m%d.%H%M%S")
BUILDDIR:=_build
SRCDIR:=$(shell pwd)
GO_SRC_FILES=$(shell find . -type f -name '*.go')
DOCKER_INPUTS=Dockerfile $(GO_SRC_FILES) vendor/
SHELL=/bin/bash

# local development targets

build: emitter

emitter: $(GO_SRC_FILES) vendor
	GO111MODULE=on GOOS=linux GOARCH=amd64 go build -o $(BUILDDIR)/emitter main.go

vendor: go.mod go.sum
	GO111MODULE=on go mod vendor

clean:
	if [ -d $(BUILDDIR) ]; then rm -rf $(BUILDDIR); fi

# `latest` builds and pushes the latest tag to ECR

latest: docker-build-latest docker-push-latest

docker-build-latest: build
	docker build . -t $(CONTAINER_NAME):latest

docker-run-latest: docker-build-latest
	docker run --rm $(CONTAINER_NAME):latest

docker-push-latest: docker-build-latest ecr-login
	docker tag $(CONTAINER_NAME):latest $(ECR_REPO)/$(CONTAINER_NAME):latest && \
    docker push $(ECR_REPO)/$(CONTAINER_NAME):latest

# `tag` builds and pushes the tag $(TAG) to ECR, if not passed in YYYYMMDD.HHMMSS is used

tag: docker-build-tag docker-push-tag

docker-build-tag: build
	docker build . -t $(CONTAINER_NAME):$(TAG)

docker-push-tag: docker-build-tag
	$(MAKE) TAG=$(TAG) docker-deploy-tag

docker-deploy-tag: ecr-login
	docker tag $(CONTAINER_NAME):$(TAG) $(ECR_REPO)/$(CONTAINER_NAME):$(TAG) && \
	docker push $(ECR_REPO)/$(CONTAINER_NAME):$(TAG)

docker-check-tag: ecr-login
	docker pull $(ECR_REPO)/$(CONTAINER_NAME):$(TAG)

# Helper Targets

ecr-login:
	@echo "Logging into ECR using aws console"
	@eval "eval $$\(aws --region $(AWS_REGION) ecr get-login --no-include-email\)"
