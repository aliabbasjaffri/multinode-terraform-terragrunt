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
    vpc_id                 = "some_id"
    vpc_public_subnets_ids = ["some-id"]
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
  aws_security_group = {
    name        = "allow-ssh-access"
    description = "Allow access on port 22"
    vpc_id      = dependency.vpc.outputs.vpc_id
    ingress = {
      description      = "Allow SSH access"
      protocol         = "tcp"
      from_port        = 22
      to_port          = 22
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = null
    }
    tags = {
      Name = "sg_allow_tls"
    }
  }

  aws_eks_cluster = {
    name    = "eks-cluster"
    subnets = dependency.vpc.outputs.vpc_public_subnets_ids
    tags    = local.tags
  }

  aws_node_groups = {
    "OpsAppsNode" = {
      subnet_ids                  = dependency.vpc.outputs.vpc_public_subnets_ids
      scaling_config_desired_size = 1
      scaling_config_max_size     = 2
      scaling_config_min_size     = 1
      update_config               = 1
    },
    "Applications" = {
      subnet_ids                  = dependency.vpc.outputs.vpc_public_subnets_ids
      scaling_config_desired_size = 1
      scaling_config_max_size     = 2
      scaling_config_min_size     = 1
      update_config               = 1
    }
  }
}

terraform {
  source = "${get_parent_terragrunt_dir("root")}/..//terraform/aws_eks_cluster"
}