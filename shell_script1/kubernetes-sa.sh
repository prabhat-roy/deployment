#!/bin/bash

set -e

echo "[INFO] Creating Jenkins Kubernetes Service Account and ClusterRoleBinding..."

kubectl apply -f jenkinsfile/kubernetes-sa.yaml
