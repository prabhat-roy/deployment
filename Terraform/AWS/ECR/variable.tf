variable "ecr_repo_names" {
  type        = list(string)
  description = "List of ECR repository names"
}

variable "aws_region" {
  type        = string
  description = "AWS Region for deployment"
}
