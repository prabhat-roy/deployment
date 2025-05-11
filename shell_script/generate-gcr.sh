#!/bin/bash

set -e

echo "📦 Loading environment variables from .env..."
set -o allexport
source .env
set +o allexport

IFS=' ' read -r -a repos_array <<< "$GCR_REPOS"
terraform_list=$(printf '"%s", ' "${repos_array[@]}")
terraform_list="[${terraform_list%, }]"

echo "🛠️ Writing terraform.tfvars..."
cat > terraform/terraform.tfvars <<EOF
gcp_project_id = "${GCP_PROJECT_ID}"
gcr_repos      = ${terraform_list}
gcp_region     = "${GCP_REGION}"
EOF

echo "🚀 Running Terraform..."
cd terraform
terraform init -input=false
terraform apply -auto-approve
