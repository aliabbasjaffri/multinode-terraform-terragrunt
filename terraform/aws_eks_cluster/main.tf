resource "aws_iam_role" "eks_role" {
  name = "eks-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "eks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role" "node_group_role" {
  name = "node-group-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "cluster_autoscaler_policy" {
  name        = "cluster_autoscaler_policy"
  description = "access to nodes to scale out and in"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Resource = "*"
        Effect   = "Allow"
        Action = [
          "autoscaling:DescribeTags",
          "autoscaling:SetDesiredCapacity",
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:TerminateInstanceInAutoScalingGroup"
        ]
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "policy_attachment_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_role.name
}

resource "aws_iam_role_policy_attachment" "policy_attachment_AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks_role.name
}

resource "aws_iam_role_policy_attachment" "policy_attachment_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group_role.name
}

resource "aws_iam_role_policy_attachment" "policy_attachment_AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group_role.name
}

resource "aws_iam_role_policy_attachment" "policy_attachment_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group_role.name
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler_policy_attachment" {
  policy_arn = aws_iam_policy.cluster_autoscaler_policy.arn
  role = aws_iam_role.node_group_role.name
}

resource "aws_security_group" "sg_eks_cluster" {
  name        = var.aws_security_group_cluster.name
  description = var.aws_security_group_cluster.description
  vpc_id      = var.aws_security_group_cluster.vpc_id

  tags = var.aws_security_group_cluster.tags
}

resource "aws_security_group" "sg_eks_nodes" {
  name        = var.aws_security_group_node.name
  description = var.aws_security_group_node.description
  vpc_id      = var.aws_security_group_node.vpc_id
  egress {
    from_port   = var.aws_security_group_node.egress.from_port
    to_port     = var.aws_security_group_node.egress.to_port
    protocol    = var.aws_security_group_node.egress.protocol
    cidr_blocks = var.aws_security_group_node.egress.cidr_blocks
  }
  tags = var.aws_security_group_node.tags
}

resource "aws_security_group_rule" "sg_rules_eks_cluster" {
  for_each                 = var.sg_rules_eks_cluster
  type                     = each.value.type
  description              = each.value.description
  from_port                = each.value.from_port
  to_port                  = each.value.to_port
  protocol                 = each.value.protocol
  security_group_id        = aws_security_group.sg_eks_cluster.id
  source_security_group_id = aws_security_group.sg_eks_nodes.id
}

resource "aws_security_group_rule" "sg_rule_intra_node" {
  type                     = var.sg_rule_intra_node.type
  description              = var.sg_rule_intra_node.description
  from_port                = var.sg_rule_intra_node.from_port
  to_port                  = var.sg_rule_intra_node.to_port
  protocol                 = var.sg_rule_intra_node.protocol
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.eks_nodes.id
}

resource "aws_security_group_rule" "sg_rule_nodes_incoming_from_cluster" {
  type                     = var.sg_rule_nodes_incoming_from_cluster.type
  description              = var.sg_rule_nodes_incoming_from_cluster.description
  from_port                = var.sg_rule_nodes_incoming_from_cluster.from_port
  to_port                  = var.sg_rule_nodes_incoming_from_cluster.to_port
  protocol                 = var.sg_rule_nodes_incoming_from_cluster.protocol
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.eks_cluster.id
}

resource "aws_eks_cluster" "eks_cluster" {
  name     = var.aws_eks_cluster.name
  role_arn = aws_iam_role.eks_role.arn

  vpc_config {
    subnet_ids         = var.aws_eks_cluster.subnets
    security_group_ids = flatten(aws_security_group.allow_ssh.id)
  }

  tags = var.aws_eks_cluster.tags

  depends_on = [
    aws_iam_role_policy_attachment.policy_attachment_AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.policy_attachment_AmazonEKSVPCResourceController,
  ]
}

resource "aws_eks_node_group" "eks_node_groups" {
  for_each        = var.aws_node_groups
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = each.key
  node_role_arn   = aws_iam_role.node_group_role.arn
  subnet_ids      = each.value.subnet_ids

  instance_types = ["t3.micro"]
  capacity_type  = "ON_DEMAND"

  scaling_config {
    desired_size = each.value.scaling_config_desired_size
    max_size     = each.value.scaling_config_max_size
    min_size     = each.value.scaling_config_min_size
  }

  update_config {
    max_unavailable = each.value.update_config
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.policy_attachment_AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.policy_attachment_AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.policy_attachment_AmazonEC2ContainerRegistryReadOnly,
  ]
}
