#!/bin/bash

set -e

# This script builds and pushes Docker images to the ECR repositories
# Usage: ./image-build-script.sh <account-id> <region> <environment> <app-name>

if [ "$#" -ne 4 ]; then
  echo "Usage: $0 <account-id> <region> <environment> <app-name>"
  echo "Example: $0 123456789012 us-east-1 Development apisix-app"
  exit 1
fi

ACCOUNT_ID=$1
REGION=$2
ENVIRONMENT=$3
APP_NAME=$4

# Login to ECR
echo "Logging in to Amazon ECR..."
aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com

# Build and push NodeJS app
NODE_REPO="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/${APP_NAME}-nodejs:latest"
echo "Building NodeJS app image..."
cd nodejs-app
DOCKER_BUILDKIT=1 docker build --platform linux/amd64 -t $NODE_REPO .
echo "Pushing NodeJS app image to $NODE_REPO"
docker push $NODE_REPO
cd ..

# Build and push APISIX image with custom config
APISIX_REPO="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/${APP_NAME}-apisix:latest"
echo "Building APISIX image..."
cat > Dockerfile.apisix << EOF
FROM apache/apisix:3.8.0-debian
COPY apisix-config.yaml /usr/local/apisix/conf/config.yaml
COPY apisix-routes.yaml /usr/local/apisix/conf/apisix.yaml
EOF

DOCKER_BUILDKIT=1 docker build --platform linux/amd64 -t $APISIX_REPO -f Dockerfile.apisix .
echo "Pushing APISIX image to $APISIX_REPO"
docker push $APISIX_REPO

# Pull and push APISIX Dashboard image
DASHBOARD_REPO="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/${APP_NAME}-dashboard:latest"
echo "Pulling APISIX Dashboard image..."
docker pull --platform linux/amd64 apache/apisix-dashboard:3.0.1-alpine
docker tag apache/apisix-dashboard:3.0.1-alpine $DASHBOARD_REPO
echo "Pushing APISIX Dashboard image to $DASHBOARD_REPO"
docker push $DASHBOARD_REPO

# Pull and push Etcd image
ETCD_REPO="$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/${APP_NAME}-etcd:latest"
echo "Pulling Etcd image..."
docker pull --platform linux/amd64 bitnami/etcd:3.5.9
docker tag bitnami/etcd:3.5.9 $ETCD_REPO
echo "Pushing Etcd image to $ETCD_REPO"
docker push $ETCD_REPO

echo "All images have been built and pushed successfully!"
echo ""
echo "Next steps:"
echo "1. Deploy the infrastructure CloudFormation stack using cf-infrastructure.yaml"
echo "2. Run the following commands to connect to your ECR repositories:"
echo "   aws ecr get-login-password --region $REGION | docker login --username AWS --password-stdin $ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"
echo "3. The nested template for CodeDeploy will be automatically deployed with the main stack"