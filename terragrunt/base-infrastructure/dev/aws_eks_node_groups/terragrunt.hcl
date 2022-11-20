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
    "Name" = "helm-chart-ingress-nginx"
  }

  tags = merge(include.root.locals.root_tags, include.stage.locals.tags, local.local_tags)
}

dependency "vpc" {
  config_path                             = "${get_parent_terragrunt_dir("stage")}/vpc_subnet_module"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs = {
    vpc_id                  = "some_id"
    vpc_private_subnets_ids = ["some-id"]
    vpc_public_subnets_ids  = ["some-id"]
  }
}

dependency "eks_cluster" {
  config_path                             = "${get_parent_terragrunt_dir("root")}/base-infrastructure/${include.stage.locals.stage}/aws_eks_cluster"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs = {
    eks_cluster_name     = "some_name"
    eks_cluster_endpoint = "some_id"
    eks_cluster_ca_cert  = "some_cert"
    eks_cluster_primary_security_group_id = "some_id"
    eks_cluster_security_group_id = "some_id"
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
  kubernetes {
    host                   = "${dependency.eks_cluster.outputs.eks_cluster_endpoint}"
    cluster_ca_certificate = base64decode("${dependency.eks_cluster.outputs.eks_cluster_ca_cert}")
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args        = ["eks", "get-token", "--cluster-name", "${dependency.eks_cluster.outputs.eks_cluster_name}"]
    }
  }
}
EOF
}

inputs = {
  aws_eks_node_groups = {
    name    = "eks-cluster"
    vpc_id  = dependency.vpc.outputs.vpc_id
    subnets = dependency.vpc.outputs.vpc_public_subnets_ids
    cluster_version = "1.24"
    cluster_primary_security_group_id = dependency.eks_cluster.outputs.eks_cluster_primary_security_group_id
    cluster_security_group_id = dependency.eks_cluster.outputs.eks_cluster_security_group_id
    tags    = local.tags
  }
}

terraform {
  source = "${get_parent_terragrunt_dir("root")}/..//terraform/aws_eks_node_groups"
}