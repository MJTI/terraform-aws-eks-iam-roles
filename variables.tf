variable "region" {
  description = "AWS region name that will be using"
  type        = string
}

variable "env" {
  description = "environment (prod - dev - stage)"
  type        = string
}

variable "project" {
  description = "The name of the project"
  type        = string
}

variable "eks_cluster_name" {
  description = "Cluster Name"
  type = string
}

variable "devops_users" {
  description = "DevOps team users"
  type        = list(string)
}

variable "developer_users" {
  description = "Developer team users"
  type        = list(string)
}

variable "eks_host" {
  description = "EKS Cluster Host"
  type = string
}

variable "cluster_ca_certificate" {
  description = "Cluster CA Certificate"
  type = string
}