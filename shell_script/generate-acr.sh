#!/bin/bash

set -e

echo "📦 Loading .env variables..."
set -o allexport
source .env
set +o allexport

IFS=' ' read -r -a repos_array <<< "$ACR_REPOS"
terraform_list=$(printf '"%s", ' "${repos_array[@]}")
terraform_list="[${terraform_list%, }]"

echo "🛠️ Writing terraform.tfvars..."
cat > terraform/terraform.tfvars <<EOF
acr_repo_names       = ${terraform_list}
azure_location       = "${AZURE_LOCATION}"
azure_resource_group = "${AZURE_RESOURCE_GROUP}"
azure_acr_name       = "${AZURE_ACR_NAME}"
EOF

echo "🚀 Running Terraform..."
cd terraform
terraform init -input=false
terraform apply -auto-approve
