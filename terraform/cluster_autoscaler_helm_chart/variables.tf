variable "cluster_autoscaler_irsa" {
  type = object({
    role_name_prefix                 = string
    role_description                 = string
    attach_cluster_autoscaler_policy = bool
    cluster_autoscaler_cluster_ids   = string
    eks_provider_arn                 = string
  })
}

variable "cluster_autoscaler_helm_chart" {
  type = object({
    name             = string
    namespace        = string
    create_namespace = bool
    repository       = string
    chart            = string
    chart_version    = string
    values           = any
    set = optional(list(object({
      name  = string
      value = any
      type  = string
    })))
  })
}