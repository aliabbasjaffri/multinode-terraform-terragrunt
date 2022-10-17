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
    vpc_private_subnets_ids = ["some-id"] 
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
  aws_security_group_cluster = {
    name        = "sg_eks_cluster"
    description = "eks cluster secured network comms with nodes"
    vpc_id      = dependency.vpc.outputs.vpc_id
    tags = {
      Name = "sg_eks_cluster"
    }
  }

  aws_security_group_nodes = {
    name        = "sg_eks_node"
    description = "Security group for all nodes in the cluster"
    vpc_id      = dependency.vpc.outputs.vpc_id
    egress = {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
      Name = var.nodes_sg_name
    }
  }

  sg_rules_eks_cluster = {
    "node_to_cluster" = {
      type        = "ingress"
      description = "Allow worker nodes to communicate with the cluster API Server"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
    },
    "cluster_to_node" = {
      type        = "egress"
      description = "Allow cluster API Server to communicate with the worker nodes"
      from_port   = 1024
      to_port     = 65535
      protocol    = "tcp"
    }
  }

  sg_rule_intra_node = {
    type                     = "ingress"
    description              = "Allow nodes to communicate with each other"
    from_port                = 0
    to_port                  = 65535
    protocol                 = "-1"
  }

  sg_rule_nodes_incoming_from_cluster = {
    type                     = "ingress"
    description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
    from_port                = 1025
    to_port                  = 65535
    protocol                 = "tcp"
  }

  aws_eks_cluster = {
    name    = "eks-cluster"
    subnets = dependency.vpc.outputs.vpc_public_subnets_ids
    tags    = local.tags
  }

  aws_node_groups = {
    "OpsAppsNode" = {
      subnet_ids                  = dependency.vpc.outputs.vpc_private_subnets_ids
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