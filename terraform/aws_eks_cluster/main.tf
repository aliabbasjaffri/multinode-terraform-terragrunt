################################################################################
# Supporting Resources
################################################################################

resource "aws_kms_key" "eks" {
  description             = "EKS Secret Encryption Key"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  tags = var.aws_eks_cluster.tags
}

resource "aws_security_group" "additional" {
  name_prefix = "${var.aws_eks_cluster.name}-additional-sg"
  vpc_id      = var.aws_eks_cluster.vpc_id

  ingress {
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
    cidr_blocks = [
      "10.0.0.0/8",
      "172.16.0.0/12",
      "192.168.0.0/16",
    ]
  }

  tags = var.aws_eks_cluster.tags
}

################################################################################
# Supporting Resources
################################################################################


################################################################################
# EKS Module
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.30.3"

  cluster_name                    = var.aws_eks_cluster.name
  cluster_version                 = var.aws_eks_cluster.cluster_version
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true

  cluster_addons = {
    # coredns = {
    #   resolve_conflicts = "OVERWRITE"
    # }
    kube-proxy = {}
    # vpc-cni = {
    #   resolve_conflicts        = "OVERWRITE"
    #   service_account_role_arn = module.vpc_cni_irsa.iam_role_arn
    # }
  }

  cluster_encryption_config = [{
    provider_key_arn = aws_kms_key.eks.arn
    resources        = ["secrets"]
  }]

  vpc_id     = var.aws_eks_cluster.vpc_id
  subnet_ids = var.aws_eks_cluster.subnets

  # Extend cluster security group rules
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

  # Extend node-to-node security group rules
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

  # eks_managed_node_group_defaults = {
  #   iam_role_attach_cni_policy = true
  # }

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

  tags = var.aws_eks_cluster.tags
}

################################################################################
# EKS Module
################################################################################

module "vpc_cni_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 4.12"

  role_name_prefix = "VPC-CNI-IRSA"
  attach_vpc_cni_policy = true
  vpc_cni_enable_ipv4   = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-node"]
    }
  }

  tags = var.aws_eks_cluster.tags
}