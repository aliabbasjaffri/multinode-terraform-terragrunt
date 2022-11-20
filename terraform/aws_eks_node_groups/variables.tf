variable "aws_eks_node_groups" {
  type = object({
    name    = string
    vpc_id  = string
    subnets = list(string)
    cluster_version = string
    cluster_primary_security_group_id = string
    cluster_security_group_id = string
    tags    = map(any)
  })
}