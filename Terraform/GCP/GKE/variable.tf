variable "worker_node_size" {
  description = "Machine type for GKE worker nodes"
  type        = string
}

variable "gcp_region" {

}
variable "vpc_name" {
  description = "Name of the existing VPC network"
  type        = string
}

variable "project_id" {

}
variable "private_subnet_name" {
  type = string
}

variable "disk_size" {
  type = number
}