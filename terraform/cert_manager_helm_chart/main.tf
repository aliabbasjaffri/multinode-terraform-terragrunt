data "kubectl_file_documents" "crds_yaml" {
  content = file("cert-manager.crds.yaml")
}

resource "kubectl_manifest" "apply_crds" {
  for_each  = data.kubectl_file_documents.crds_yaml.manifests
  yaml_body = each.value
}

module "cert_manager" {
  source = "../helm_chart"

  helm_chart = var.cert_manager_helm_chart
  depends_on = [kubectl_manifest.apply_crds]
}
