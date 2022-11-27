output "eks_cluster_name" {
  value = var.aws_eks_cluster.name
}

output "eks_cluster_id" {
  value = module.eks.cluster_id
}

output "eks_cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "eks_cluster_ca_cert" {
  value = module.eks.cluster_certificate_authority_data
}

output "eks_cluster_primary_security_group_id" {
  value = module.eks.cluster_primary_security_group_id
}

output "eks_cluster_security_group_id" {
  value = module.eks.cluster_security_group_id
}

output "eks_oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}
