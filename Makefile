#!/bin/bash -xe

# include .env
# export 

APP_NAME := basic-demo-microservice-01
DOCKERFILE := Dockerfile
LOCAL_IMAGE_NAME := $(APP_NAME):local
PROD_IMAGE_NAME := $(APP_NAME):latest

# Build the local image
build-local:
	docker build -f $(DOCKERFILE) -t $(LOCAL_IMAGE_NAME) .

# Run local container
run-local:
	make build-local && \
	docker run -p 8080:80 \
	$(LOCAL_IMAGE_NAME)

# Build the production image
build-prod:
	docker build -f $(DOCKERFILE) -t $(PROD_IMAGE_NAME) .

# Push manually the production image to ECR
push-prod:
	./ecr-login.sh && \
	docker tag $(PROD_IMAGE_NAME) 933673765333.dkr.ecr.us-east-1.amazonaws.com/basic-demo-microservice-01:latest && \
	docker push 933673765333.dkr.ecr.us-east-1.amazonaws.com/basic-demo-microservice-01

# Run production container
# run-prod:

# Shell into running container
debug:
	@RUNNING_CONTAINER=$$(docker ps --filter "ancestor=$(LOCAL_IMAGE_NAME)" --format "{{.ID}}" | head -n1); \
	if [ -z "$$RUNNING_CONTAINER" ]; then \
		echo "No running container found for image $(LOCAL_IMAGE_NAME)"; \
		exit 1; \
	fi; \
	echo "Attaching to container $$RUNNING_CONTAINER"; \
	docker exec -it $$RUNNING_CONTAINER sh

# Clean all Docker cache and volumes
clean:
	docker system prune -a --volumes -f && docker builder prune -a -f

# Show status
status:
	docker ps --filter "name=$(APP_NAME)"
