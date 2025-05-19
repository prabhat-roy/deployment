#!/bin/bash
set -euo pipefail

ACTION=${1:-}

if [[ -z "${AWS_REGION:-}" ]]; then
  echo "❌ AWS_REGION environment variable is not set"
  exit 1
fi

export TF_VAR_aws_region="$AWS_REGION"

cd Terraform/AWS/EKS || exit 1

terraform init -upgrade
terraform "$ACTION" -auto-approve
