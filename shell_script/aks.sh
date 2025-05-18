#!/bin/bash
set -euo pipefail

ACTION=${1:-}
cd Terraform/Azure/AKS || exit 1

terraform init -upgrade
terraform "$ACTION" -auto-approve
