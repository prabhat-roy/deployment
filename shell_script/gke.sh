#!/bin/bash
set -euo pipefail

ACTION=${1:-}
cd Terraform/GCP/GKE || exit 1

terraform init -upgrade
terraform "$ACTION" -auto-approve
