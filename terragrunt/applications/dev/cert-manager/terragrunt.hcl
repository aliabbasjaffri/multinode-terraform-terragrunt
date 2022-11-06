include "root" {
  path   = find_in_parent_folders("root-config.hcl")
  expose = true
}

include "stage" {
  path   = find_in_parent_folders("stage.hcl")
  expose = true
}

locals {
  # merge tags
  local_tags = {
    "Name" = "helm-chart-cert-manager"
  }

  tags = merge(include.root.locals.root_tags, include.stage.locals.tags, local.local_tags)
}

dependency "eks_cluster" {
  config_path                             = "${get_parent_terragrunt_dir("root")}/base-infrastructure/${include.stage.locals.stage}/aws_eks_cluster"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs = {
    eks_cluster_name     = "some_name"
    eks_cluster_endpoint = "some_id"
    eks_cluster_ca_cert  = "some-id"
  }
}

generate "provider_global" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  backend "s3" {}
  required_version = "${include.root.locals.version_terraform}"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "${include.root.locals.version_provider_aws}"
    }
    helm = {
      source = "hashicorp/helm"
      version = "${include.root.locals.version_provider_helm}"
    }
  }
}

provider "aws" {
  region = "${include.root.locals.region}"
}
provider "helm" {
  debug = true
  kubernetes {
    host                   = "${dependency.eks_cluster.outputs.eks_cluster_endpoint}"
    cluster_ca_certificate = "${dependency.eks_cluster.outputs.eks_cluster_ca_cert}"
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", "${dependency.eks_cluster.outputs.eks_cluster_name}"]
      command     = "aws"
    }
  }
}
EOF
}

inputs = {
  helm_chart = {
    name          = "jetstack"
    repository    = "https://charts.jetstack.io"
    chart         = "jetstack/cert-manager"
    chart_version = "1.10.0"
    values        = "${file("values.yaml")}"
    set = [{
      name  = "nodeSelector",
      value = "{ name : OpsApps }",
      type  = "auto"
      }, {
      name  = "webhook.nodeSelector",
      value = "{ name : OpsApps }",
      type  = "auto"
      }, {
      name  = "cainjector.nodeSelector",
      value = "{ name : OpsApps }",
      type  = "auto"
      }, {
      name  = "startupapicheck.nodeSelector",
      value = "{ name : OpsApps }",
      type  = "auto"
      }
      # add node affinity and taints
    ]
  }
}

terraform {
  source = "${get_parent_terragrunt_dir("root")}/..//terraform/helm_chart"
}