#!/bin/bash
# This script is used to deploy the application to the server
set -e

IMAGE="poovarasane/mydevopsapp"
TAG='v2'
## Pull latest changes from the repository
echo "Pulling latest changes from the repository..."
git pull origin main

##Build docker image
echo "Building Docker image..."
docker build -t $IMAGE:$TAG  .

## Push the image to Docker Hub
echo "Pushing Docker image to Docker Hub..."
docker push $IMAGE:$TAG

##Deploy the application using helm
echo "Deploying the application using Helm..."
helm upgrade --install mydevopsapp ./mychart --set container.image=$IMAGE:$TAG


###Verify the deployment
echo "Verifying the deployment..."
kubectl rollout status deployment/mydevopsapp-deployment

echo "Deployment successful!"
kubectl get pods