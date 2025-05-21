#!/bin/bash
set -euo pipefail

ACTION=${1:-}

if [[ -z "${TF_VAR_region:-}" ]]; then
  echo "❌ TF_VAR_region environment variable is not set"
  exit 1
fi

cd Terraform/AWS/EKS || exit 1

terraform init -upgrade
terraform "$ACTION" -auto-approve
