terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }

  # If this folder runs as its own HCP Terraform workspace, add the cloud block
  # the same way the existing root / security-groups workspaces do, e.g.:
  # cloud {
  #   organization = "<your-hcp-org>"
  #   workspaces { name = "iec-ws-aws-ecs-service-dev" }
  # }
}

provider "aws" {
  region = var.aws_region

  assume_role {
    role_arn = var.assume_role_arn
  }

  default_tags {
    tags = var.tags
  }
}
