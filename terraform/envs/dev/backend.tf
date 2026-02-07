terraform {
  backend "s3" {
    bucket       = "ayoub-eks-gitops-tfstate"
    key          = "envs/dev/terraform.tfstate"
    region       = "eu-west-3"
    use_lockfile = true
  }
}
