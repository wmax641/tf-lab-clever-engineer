provider "aws" {
  region = "ap-southeast-2"
}
provider "archive" {}

terraform {
  backend "s3" {
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

module "lab_instance" {
  source = "./instance"
  count  = var.instance_count

  base_name   = var.base_name
  common_tags = var.common_tags
  vpc_id      = aws_vpc.vpc.id
  subnet_id   = aws_subnet.subnet_public.id
  sg_id       = aws_security_group.instance_sg.id
}
