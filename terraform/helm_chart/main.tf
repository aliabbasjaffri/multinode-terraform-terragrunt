resource "helm_release" "helm_chart" {
  name             = var.helm_chart.name
  namespace        = var.helm_chart.namespace
  create_namespace = var.helm_chart.create_namespace
  repository       = var.helm_chart.repository
  chart            = var.helm_chart.chart
  version          = var.helm_chart.chart_version
  cleanup_on_fail  = true
  values           = [var.helm_chart.values]

  dynamic "set" {
    for_each = var.helm_chart.set
    content {
      name  = set.value.name
      value = set.value.value
      type  = set.value.type
    }
  }
}