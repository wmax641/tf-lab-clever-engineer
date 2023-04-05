provider "aws" {
  region = "ap-southeast-2"
}
provider "archive" {}

terraform {
  backend "local" {
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.61"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4.3"
    }
  }
}

module "victim_server" {
  source = "./victim_server"
  count  = 2

  base_name   = var.base_name
  vpc_id      = aws_vpc.vpc.id
  subnet_id   = aws_subnet.subnet.id
  common_tags = var.common_tags
}
