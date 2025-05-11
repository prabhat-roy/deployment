#!/bin/bash

set -e

NAMESPACE="elastic"
RELEASE_NAME="elastic-stack"
CHART_PATH="elastic-stack/elastic"   # Adjust this to your Helm chart path
VALUES_FILE="elastic-stack/values.yaml"  # Adjust as needed

echo "Ensuring namespace '$NAMESPACE' exists..."
kubectl get ns $NAMESPACE >/dev/null 2>&1 || kubectl create ns $NAMESPACE

echo "Deploying Elastic Stack using Helm..."

helm upgrade --install $RELEASE_NAME $CHART_PATH \
  --namespace $NAMESPACE \
  --create-namespace \
  -f $VALUES_FILE \
  --wait

echo "Elastic Stack Helm chart deployed successfully in namespace '$NAMESPACE'."
