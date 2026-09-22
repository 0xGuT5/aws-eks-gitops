terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = "eu-west-3"

  default_tags {
    tags = {
      project = "aws-eks-gitops"
      env     = "dev"
    }
  }
}

provider "helm" {
  kubernetes = {
    host                   = module.cluster.cluster_endpoint
    cluster_ca_certificate = base64decode(module.cluster.cluster_certificate_authority_data)

    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", module.cluster.cluster_name, "--region", "eu-west-3"]
    }
  }
}

module "cluster" {
  source = "../../modules/cluster"

  name     = "gitops-dev"
  env      = "dev"
  vpc_cidr = "10.10.0.0/16"

  gitops_repo = "https://github.com/0xGuT5/aws-eks-gitops.git"
  base_domain = "example.com"

  node_instance_types = ["t3.large"]
  node_min            = 2
  node_max            = 3
}
