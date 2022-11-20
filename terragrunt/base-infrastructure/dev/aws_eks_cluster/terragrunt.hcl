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
    "Name" = "eks-cluster"
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
  }
}

provider "aws" {
  region = "${include.root.locals.region}"
}
EOF
}

inputs = {
  aws_eks_cluster = {
    name    = "eks-cluster"
    vpc_id  = dependency.vpc.outputs.vpc_id
    subnets = dependency.vpc.outputs.vpc_public_subnets_ids
    cluster_version = "1.24"
    tags    = local.tags
  }
}

terraform {
  source = "${get_parent_terragrunt_dir("root")}/..//terraform/aws_eks_cluster"
}