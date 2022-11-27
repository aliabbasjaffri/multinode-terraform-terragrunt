variable "cert_manager_helm_chart" {
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