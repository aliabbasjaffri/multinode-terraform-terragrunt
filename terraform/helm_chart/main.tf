resource "helm_release" "helm_chart" {
  name       = var.helm_chart.name
  repository = var.helm_chart.repository
  chart      = var.helm_chart.chart
  version    = var.helm_chart.chart_version

  values = [var.helm_chart.values]

  dynamic "set" {
    for_each = var.helm_chart.set
    content {
      name  = set.value.name
      value = set.value.value
      type  = set.value.type
    }
  }
}