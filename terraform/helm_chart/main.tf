resource "helm_release" "helm_chart" {
  name       = var.helm_release.name
  repository = var.helm_release.repository
  chart      = var.helm_release.chart
  version    = var.helm_release.chart_version

  values = var.helm_release.values

  dynamic "set" {
    for_each = var.helm_release.set_values
    name     = set.value.name
    value    = set.value.value
  }
}