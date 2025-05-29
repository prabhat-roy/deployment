variable "aws_region" {
  type        = string
  description = "AWS Region"
}

variable "cluster_name" {
  type        = string
  description = "EKS cluster name"
}

variable "karpenter_namespace" {
  type        = string
  description = "Namespace where Karpenter will be deployed"
  default     = "karpenter"
}

variable "instance_types" {
  type        = list(string)
  description = "Allowed instance types for Karpenter to provision"
  default     = ["m5.large", "m5.xlarge"]
}

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs where Karpenter can launch instances"
}

variable "cluster_endpoint" {
  type        = string
  description = "EKS cluster endpoint"
  default     = ""
}

variable "cluster_ca" {
  type        = string
  description = "Cluster CA certificate"
  default     = ""
}
