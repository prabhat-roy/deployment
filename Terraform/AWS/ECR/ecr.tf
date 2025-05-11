provider "aws" {
  region = var.aws_region
}

resource "aws_ecr_repository" "repos" {
  for_each = var.ecr_repo_names

  name = each.value

  image_scanning_configuration {
    scan_on_push = false
  }

  force_delete = true

  tags = {
    CreatedBy   = "Terraform"
  
  }
}
