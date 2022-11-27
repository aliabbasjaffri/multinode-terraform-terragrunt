module "cluster_autoscaler_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 4.12"

  role_name_prefix = var.cluster_autoscaler_irsa.role_name_prefix
  role_description = var.cluster_autoscaler_irsa.role_description

  attach_cluster_autoscaler_policy = var.cluster_autoscaler_irsa.attach_cluster_autoscaler_policy
  cluster_autoscaler_cluster_ids   = [var.cluster_autoscaler_irsa.cluster_autoscaler_cluster_ids]

  oidc_providers = {
    main = {
      provider_arn               = var.cluster_autoscaler_irsa.eks_provider_arn
      namespace_service_accounts = ["kube-system:${var.cluster_autoscaler_irsa.role_name_prefix}-aws"]
    }
  }

  # tags = local.tags
}

locals {
  value_set = setunion(var.cluster_autoscaler_helm_chart.set, [{
    name : "rbac.serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn",
    value : module.cluster_autoscaler_irsa.iam_role_arn,
    type : "string"
  }])
}

module "cluster_autoscaler" {
  source = "../helm_chart"

  helm_chart = {
    name             = var.cluster_autoscaler_helm_chart.name
    namespace        = var.cluster_autoscaler_helm_chart.namespace
    create_namespace = var.cluster_autoscaler_helm_chart.create_namespace
    repository       = var.cluster_autoscaler_helm_chart.repository
    chart            = var.cluster_autoscaler_helm_chart.chart
    chart_version    = var.cluster_autoscaler_helm_chart.chart_version
    values           = var.cluster_autoscaler_helm_chart.values
    set              = local.value_set
  }

  depends_on = [module.cluster_autoscaler_irsa]
}
