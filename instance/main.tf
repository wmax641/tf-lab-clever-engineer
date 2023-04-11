data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}

resource "random_string" "uniq" {
  length  = 16
  upper   = false
  special = false
}
resource "random_integer" "user_num" {
  min = 10 
  max = 99
}

resource "random_string" "cred" {
  length           = 20
  special          = true
  override_special = "~!@#$%^&*()_+?"
  min_lower        = 6
  min_upper        = 5
  min_numeric      = 4
}

locals {
  uniq_id        = random_string.uniq.result
  uniq_prefix    = "${var.base_name}-${random_string.uniq.result}"
  ssm_param_path = "/${var.base_name}-${random_string.uniq.result}"
  tags = merge(
    {
      "uniq_id"     = local.uniq_id,
      "uniq_prefix" = local.uniq_prefix
  }, var.common_tags)
}

data "aws_vpc" "vpc" {
  id = var.vpc_id
}
data "aws_subnet" "subnet" {
  id = var.subnet_id
}
