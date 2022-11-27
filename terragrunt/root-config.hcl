locals {
  region = "eu-central-1"

  version_terraform        = "=1.3.0"
  version_terragrunt       = "=0.39.1"
  version_provider_aws     = "=4.34.0"
  version_provider_vpc     = "=3.16.1"
  version_provider_helm    = "=2.7.1"
  version_provider_kubectl = "=1.14.0"

  root_tags = {
    project = "eks-terraform-terragrunt"
  }
}

generate "provider_global" {
  path      = "provider.tf"
  if_exists = "overwrite"
  contents  = <<EOF
terraform {
  required_version = "${local.version_terraform}"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "${local.version_provider_aws}"
    }
  }
}

provider "aws" {
  region = "${local.region}"
}
EOF
}


remote_state {
  backend = "s3"
  config = {
    bucket         = "eks-terraform-terragrunt-state-bucket"
    key            = "${path_relative_to_include()}/terraform.tfstate"
    encrypt        = true
    region         = local.region
    dynamodb_table = "terraform-locks-table"
  }
}