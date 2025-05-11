#!/bin/bash

set -e

echo "📦 Loading environment variables..."
set -o allexport
source Jenkins.env
set +o allexport

echo "📜 Converting ECR_REPOS to Terraform list..."
IFS=' ' read -r -a repos_array <<< "$ECR_REPOS"
terraform_list=$(printf '"%s", ' "${repos_array[@]}")
terraform_list="[${terraform_list%, }]"

echo "🛠️ Writing terraform.tfvars..."
cat > Terraform/AWS/ECR/terraform.tfvars <<EOF
ecr_repo_names = ${terraform_list}
aws_region     = "${AWS_REGION}"
EOF

echo "🚀 Running Terraform..."
cd Terraform/AWS/ECR
terraform init -input=false
terraform apply -auto-approve
