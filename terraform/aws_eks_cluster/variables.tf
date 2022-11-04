variable "aws_security_group_cluster" {
  type = object({
    name        = string
    description = string
    vpc_id      = string
    tags        = map(any)
  })
}

variable "aws_security_group_node" {
  type = object({
    name        = string
    description = string
    vpc_id      = string
    egress = object({
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = list(string)
    })
    tags = map(any)
  })
}

variable "sg_rules_eks_cluster" {
  type = map(object({
    type        = string
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
  }))
}

variable "sg_rule_intra_node" {
  type = object({
    type        = string
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
  })
}

variable "sg_rule_nodes_incoming_from_cluster" {
  type = object({
    type        = string
    description = string
    from_port   = number
    to_port     = number
    protocol    = string
  })
}

variable "aws_eks_cluster" {
  type = object({
    name    = string
    subnets = list(string)
    tags    = map(any)
  })
}

variable "aws_node_groups" {
  type = map(object({
    subnet_ids                  = list(string)
    scaling_config_desired_size = number
    scaling_config_max_size     = number
    scaling_config_min_size     = number
    update_config               = number
    labels                      = map(string)
  }))
}