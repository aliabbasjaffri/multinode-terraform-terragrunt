variable "aws_eks_cluster" {
  type = object({
    name            = string
    vpc_id          = string
    subnets         = list(string)
    cluster_version = string
    tags            = map(any)
  })
}