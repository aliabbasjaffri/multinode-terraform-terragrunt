output "eks_cluster_name" {
  value = var.aws_eks_cluster.name
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "eks_cluster_ca_cert" {
  value = module.eks.cluster_certificate_authority_data
}