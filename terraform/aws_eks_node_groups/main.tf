module "eks_managed_node_groups" {
  source = "terraform-aws-modules/eks/aws//modules/eks-managed-node-group"

  name            = "separate-eks-mng"
  cluster_name    = var.aws_eks_node_groups.name
  cluster_version = var.aws_eks_node_groups.cluster_version

  vpc_id     = var.aws_eks_node_groups.vpc_id
  subnet_ids = var.aws_eks_node_groups.subnets

  // The following variables are necessary if you decide to use the module outside of the parent EKS module context.
  // Without it, the security groups of the nodes are empty and thus won't join the cluster.
  cluster_primary_security_group_id = var.aws_eks_node_groups.cluster_primary_security_group_id
  cluster_security_group_id = var.aws_eks_node_groups.cluster_security_group_id

  min_size     = 1
  max_size     = 10
  desired_size = 1

  instance_types = ["t3.large"]
  capacity_type  = "SPOT"

  labels = {
    Environment = "test"
    GithubRepo  = "terraform-aws-eks"
    GithubOrg   = "terraform-aws-modules"
  }

  taints = {
    dedicated = {
      key    = "dedicated"
      value  = "gpuGroup"
      effect = "NO_SCHEDULE"
    }
  }

  tags = {
    Environment = "dev"
    Terraform   = "true"
  }
}

################################################################################
# Tags for the ASG to support cluster-autoscaler scale up from 0
################################################################################

# locals {

#   # We need to lookup K8s taint effect from the AWS API value
#   taint_effects = {
#     NO_SCHEDULE        = "NoSchedule"
#     NO_EXECUTE         = "NoExecute"
#     PREFER_NO_SCHEDULE = "PreferNoSchedule"
#   }

#   cluster_autoscaler_label_tags = merge([
#     for name, group in module.eks_managed_node_groups : {
#       for label_name, label_value in coalesce(group.node_group_labels, {}) : "${name}|label|${label_name}" => {
#         autoscaling_group = group.node_group_autoscaling_group_names[0],
#         key               = "k8s.io/cluster-autoscaler/node-template/label/${label_name}",
#         value             = label_value,
#       }
#     }
#   ]...)

#   cluster_autoscaler_taint_tags = merge([
#     for name, group in module.eks_managed_node_groups : {
#       for taint in coalesce(group.node_group_taints, []) : "${name}|taint|${taint.key}" => {
#         autoscaling_group = group.node_group_autoscaling_group_names[0],
#         key               = "k8s.io/cluster-autoscaler/node-template/taint/${taint.key}"
#         value             = "${taint.value}:${local.taint_effects[taint.effect]}"
#       }
#     }
#   ]...)

#   cluster_autoscaler_asg_tags = merge(local.cluster_autoscaler_label_tags, local.cluster_autoscaler_taint_tags)
# }

# resource "aws_autoscaling_group_tag" "cluster_autoscaler_label_tags" {
#   for_each = local.cluster_autoscaler_asg_tags

#   autoscaling_group_name = each.value.autoscaling_group

#   tag {
#     key   = each.value.key
#     value = each.value.value

#     propagate_at_launch = false
#   }
# }