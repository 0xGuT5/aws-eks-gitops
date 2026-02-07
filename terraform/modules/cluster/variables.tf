variable "name" {
  type = string
}

variable "env" {
  type = string
}

variable "kubernetes_version" {
  type    = string
  default = "1.35"
}

variable "vpc_cidr" {
  type = string
}

variable "node_instance_types" {
  type    = list(string)
  default = ["t3.large"]
}

variable "node_min" {
  type    = number
  default = 2
}

variable "node_max" {
  type    = number
  default = 3
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "gitops_repo" {
  type        = string
  description = "repo argocd pulls from"
}

variable "base_domain" {
  type        = string
  description = "apps are exposed as <app>.<env>.<base_domain>"
}
