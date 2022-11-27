module "cluster_autoscaler_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 4.12"

  role_name_prefix = "cluster-autoscaler"
  role_description = "IRSA role for cluster autoscaler"

  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_ids   = [module.eks.cluster_id]

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:cluster-autoscaler-aws"]
    }
  }

  tags = local.tags
}

module "cert_manager" {
  source = "../helm_chart"

  helm_chart = var.cert_manager_helm_chart.helm_chart
  depends_on = [kubectl_manifest.apply_crds]
}
