resource "kubernetes_manifest" "manifest" {
  manifest = yamldecode(<<-EOF
    ${var.kubernetes_manifest}
    EOF
  )
}