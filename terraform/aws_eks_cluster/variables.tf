variable "aws_security_group" {
  type = object({
    name        = string
    description = string
    vpc_id      = string
    ingress = object({
      description      = string
      protocol         = string
      from_port        = number
      to_port          = number
      cidr_blocks      = list(string)
      ipv6_cidr_blocks = list(string)
    })
    tags = map(any)
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
  }))
}