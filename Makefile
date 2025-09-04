MONIT_VERSION=5.35.2
ALPINE_VERSION=3.22.1
DOCKER_USER=greycubesgav
DOCKER_IMAGE_NAME=monit
DOCKER_IMAGE_VERSION=$(MONIT_VERSION)
DOCKER_PLATFORM=linux/amd64

default: docker-build-image

docker-build-image:
	docker build --platform $(DOCKER_PLATFORM) \
		--build-arg ALPINE_VERSION=$(ALPINE_VERSION) \
		--build-arg MONIT_VERSION=$(MONIT_VERSION) \
		--file Dockerfile \
		--tag $(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_VERSION) .

docker-run-image:
	docker run --platform $(DOCKER_PLATFORM) --publish 2812:2812 --rm --name 'monit' --detach $(DOCKER_USER)/$(DOCKER_IMAGE_NAME):$(DOCKER_IMAGE_VERSION)

docker-stop-container:
	docker stop monit
