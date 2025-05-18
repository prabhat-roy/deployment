variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
}

variable "ubuntu_image_project" {
  description = "Ubuntu image project"
  type        = string
  #default     = "ubuntu-os-cloud"
}

variable "ubuntu_image_family" {
  description = "Ubuntu image family (tracks latest LTS)"
  type        = string
  #default     = "ubuntu-2404-lts"
}

variable "machine_type" {
  description = "GCP machine type for compute instance"
  type        = string
}

variable "disk_size" {
  description = "Boot disk size in GB"
  type        = number
}

variable "user" {
  description = "SSH username"
  type        = string
}

variable "HOME" {
  description = "User home directory path (injected via TF_VAR_HOME)"
  type        = string
}

variable "public_key" {
  description = "Public SSH key content"
  type        = string
  sensitive   = true

}

variable "private_key" {
  description = "Private SSH key content"
  type        = string
  sensitive   = true
}