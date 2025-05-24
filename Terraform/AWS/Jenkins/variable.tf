variable "region" {
  description = "The AWS region to deploy the resources in."
  type        = string
}


variable "aws_vpc_cidr" {
  description = "CIDR block for the VPC."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for Jenkins."
  type        = string

}
variable "key_name" {
  description = "Name of the key pair to use for SSH access."
  type        = string
}

variable "public_key_path" {
  description = "Path to your existing public key file"
  type        = string
}

variable "disk_size" {
  description = "Size of the root volume in GB."
  type        = number
}

variable "cluster_name" {
  description = "Name of the EKS cluster."
  type = string
}

variable "private_key" {
  
}