output "eks_cluster_name" {
  value = aws_eks_cluster.eks_cluster.name
}

output "eks_cluster_endpoint" {
  value = aws_eks_cluster.eks_cluster.endpoint
}

output "eks_cluster_ca_cert" {
  value = aws_eks_cluster.eks_cluster.certificate_authority[0].data
}