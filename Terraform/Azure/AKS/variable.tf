variable "subscription_id" {
  type = string
}

variable "resource_group" {
  type = string
}

variable "azure_region" {
  type = string
}

variable "aks_cluster_name" {
  type = string
}

variable "dns_prefix" {
  type = string
}

variable "kubernetes_version" {
  type = string
}

variable "worker_node_size" {
  type = string
}

variable "default_node_count" {
  type    = number
}

variable "remove_default_pool" {
    type = bool
}