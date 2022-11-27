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
  aws_kms_key = {
    description             = "EKS Secret Encryption Key"
    deletion_window_in_days = 7
    enable_key_rotation     = true
    tags                    = local.tags
  }

  aws_security_group = {
    name_prefix = "eks-cluster-additional-sg"
    vpc_id      = dependency.vpc.outputs.vpc_id
    ingresses = [{
      from_port = 22
      to_port   = 22
      protocol  = "tcp"
      cidr_blocks = [
        "10.0.0.0/8",
        "172.16.0.0/12",
        "192.168.0.0/16",
      ]
    }]
    tags = local.tags
  }

  aws_eks_cluster = {
    cluster_name                    = "eks-cluster"
    cluster_version                 = "1.24"
    cluster_endpoint_private_access = true
    cluster_endpoint_public_access  = true
    vpc_id                          = dependency.vpc.outputs.vpc_id
    subnets                         = dependency.vpc.outputs.vpc_public_subnets_ids
    cluster_security_group_additional_rules = {
      egress_nodes_ephemeral_ports_tcp = {
        description                = "To node 1025-65535"
        protocol                   = "tcp"
        from_port                  = 1025
        to_port                    = 65535
        type                       = "egress"
        source_node_security_group = true
      }
    }
    node_security_group_additional_rules = {
      ingress_self_all = {
        description = "Node to node all ports/protocols"
        protocol    = "-1"
        from_port   = 0
        to_port     = 0
        type        = "ingress"
        self        = true
      }
      egress_all = {
        description      = "Node all egress"
        protocol         = "-1"
        from_port        = 0
        to_port          = 0
        type             = "egress"
        cidr_blocks      = ["0.0.0.0/0"]
        ipv6_cidr_blocks = ["::/0"]
      }
    }
    eks_managed_node_groups = {
      default_node_group_1 = {
        create_launch_template = false
        launch_template_name   = ""

        disk_size = 50

        min_size     = 1
        max_size     = 7
        desired_size = 1

        capacity_type        = "SPOT"
        force_update_version = true
        instance_types       = ["t3.small"]
        taints               = []
      }
      default_node_group_2 = {
        create_launch_template = false
        launch_template_name   = ""

        disk_size = 50

        min_size     = 1
        max_size     = 7
        desired_size = 1

        capacity_type        = "SPOT"
        force_update_version = true
        instance_types       = ["t3.small"]

        labels = {
          NodeTypeClass = "appops"
        }

        taints = [{
          key    = "dedicated"
          value  = "appops"
          effect = "NO_SCHEDULE"
          }
        ]
      }
    }
    tags = local.tags
  }
  vpc_cni_irsa = {
    role_name_prefix      = "VPC-CNI-IRSA"
    attach_vpc_cni_policy = true
    vpc_cni_enable_ipv4   = true
    tags                  = local.tags
  }
}

terraform {
  source = "${get_parent_terragrunt_dir("root")}/..//terraform/aws_eks_cluster"
}