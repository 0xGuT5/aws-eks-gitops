output "cluster_name" {
  value = module.cluster.cluster_name
}

output "kubeconfig_command" {
  value = "aws eks update-kubeconfig --name ${module.cluster.cluster_name} --region eu-west-3"
}
