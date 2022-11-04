variable "helm_release" {
  type = object({
    name       = string
    repository = string
    chart      = string
    version    = string
    values     = string
    set = list(object({
      name  = string
      value = any
      type  = string
    }))
  })
}