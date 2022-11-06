variable "helm_chart" {
  type = object({
    name          = string
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