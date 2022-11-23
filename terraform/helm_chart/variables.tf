variable "helm_chart" {
  type = object({
    name          = string
    namespace     = string
    create_namespace = bool
    repository    = string
    chart         = string
    chart_version = string
    values        = any
    set = list(object({
      name  = string
      value = any
      type  = string
    }))
  })
}