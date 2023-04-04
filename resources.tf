data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}

resource "random_string" "uniq" {
  length  = 8
  upper   = false
  special = false
}
resource "random_string" "cred" {
  length           = 24
  special          = true
  override_special = "~!@#$%^&*()_+?"
  min_lower        = 8
  min_upper        = 5
  min_numeric      = 5
}

locals {
  uniq_id        = random_string.uniq.result
  uniq_prefix    = "${var.base_name}-${random_string.uniq.result}"
  ssm_param_path = "/${var.base_name}/${random_string.uniq.result}"
  uniq_tags      = merge({ "identifier" = "${local.uniq_prefix}" }, var.common_tags)
}

resource "aws_ssm_parameter" "cred" {
  name  = "${local.ssm_param_path}/cred"
  type  = "String"
  value = random_string.cred.result
}
resource "aws_ssm_parameter" "ip" {
  name  = "${local.ssm_param_path}/ip"
  type  = "String"
  value = "0.0.0.0"
}

resource "aws_s3_bucket" "bucket" {
  bucket = local.uniq_prefix
  tags   = merge({ "Name" = "${local.uniq_prefix}" }, local.uniq_tags)
}
resource "aws_s3_bucket_acl" "bucket_acl" {
  acl    = "private"
  bucket = aws_s3_bucket.bucket.id
}

resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge({ "Name" = "${local.uniq_prefix}-vpc" }, local.uniq_tags)
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge({ "Name" = "${local.uniq_prefix}-igw" }, local.uniq_tags)
}

resource "aws_subnet" "subnet" {
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  cidr_block              = var.cidr_block
  tags                    = merge({ "Name" = "${local.uniq_prefix}-subnet" }, local.uniq_tags)
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = merge({ "Name" = "${local.uniq_prefix}-route-table" }, local.uniq_tags)
}

resource "aws_route_table_association" "route_association" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.route_table.id
}


#data "archive_file" "list" {
#  type             = "zip"
#  source_file      = "${path.module}/lambda/list.py"
#  output_file_mode = "0666"
#  output_path      = "${path.module}/lambda/list.py.zip"
#}
#
#data "archive_file" "upload_link" {
#  type             = "zip"
#  source_file      = "${path.module}/lambda/uploadLink.py"
#  output_file_mode = "0666"
#  output_path      = "${path.module}/lambda/uploadLink.py.zip"
#}
#
#resource "aws_lambda_function" "list" {
#  filename      = data.archive_file.list.output_path
#  function_name = "${var.base_name}-list-lambda"
#  role          = aws_iam_role.lambda_read_role.arn
#  handler       = "list.lambda_handler"
#
#  source_code_hash = filebase64sha256(data.archive_file.list.output_path)
#
#  runtime = "python3.9"
#
#  environment {
#    variables = {
#      BUCKET_NAME     = aws_s3_bucket.bucket.id
#      PROTECTED_FILES = var.protected_file_list
#    }
#  }
#  tags = merge({ "Name" = "${var.base_name}-list-lambda" }, var.common_tags)
#}
#
#resource "aws_lambda_function" "upload_link" {
#  filename      = data.archive_file.upload_link.output_path
#  function_name = "${var.base_name}-uploadLink-lambda"
#  role          = aws_iam_role.lambda_write_role.arn
#  handler       = "uploadLink.lambda_handler"
#
#  source_code_hash = filebase64sha256(data.archive_file.upload_link.output_path)
#
#  runtime = "python3.9"
#
#  environment {
#    variables = {
#      BUCKET_NAME     = aws_s3_bucket.bucket.id
#      PROTECTED_FILES = var.protected_file_list
#    }
#  }
#  tags = merge({ "Name" = "${var.base_name}-uploadLink-lambda" }, var.common_tags)
#}
#
#resource "aws_apigatewayv2_api" "api_gateway" {
#  name          = var.base_name
#  protocol_type = "HTTP"
#}
#
#resource "aws_apigatewayv2_route" "list" {
#  api_id    = aws_apigatewayv2_api.api_gateway.id
#  route_key = "GET /list"
#
#  target = "integrations/${aws_apigatewayv2_integration.list.id}"
#}
#resource "aws_apigatewayv2_route" "upload_link" {
#  api_id    = aws_apigatewayv2_api.api_gateway.id
#  route_key = "GET /uploadLink"
#
#  target = "integrations/${aws_apigatewayv2_integration.upload_link.id}"
#}
#
#resource "aws_apigatewayv2_integration" "list" {
#  api_id           = aws_apigatewayv2_api.api_gateway.id
#  integration_type = "AWS_PROXY"
#
#  connection_type      = "INTERNET"
#  description          = "GET list Lambda"
#  integration_method   = "POST"
#  integration_uri      = aws_lambda_function.list.invoke_arn
#  passthrough_behavior = "WHEN_NO_MATCH"
#}
#resource "aws_apigatewayv2_integration" "upload_link" {
#  api_id           = aws_apigatewayv2_api.api_gateway.id
#  integration_type = "AWS_PROXY"
#
#  connection_type      = "INTERNET"
#  description          = "GET uploadLink Lambda"
#  integration_method   = "POST"
#  integration_uri      = aws_lambda_function.upload_link.invoke_arn
#  passthrough_behavior = "WHEN_NO_MATCH"
#}
#
#resource "aws_apigatewayv2_deployment" "deployment" {
#  api_id      = aws_apigatewayv2_api.api_gateway.id
#  description = "deployment!!"
#
#  lifecycle {
#    create_before_destroy = true
#  }
#  depends_on = [
#    aws_apigatewayv2_route.list,
#    aws_apigatewayv2_route.upload_link
#  ]
#}
#
#resource "aws_apigatewayv2_stage" "v1" {
#  api_id        = aws_apigatewayv2_api.api_gateway.id
#  name          = "v1"
#  auto_deploy   = true
#  deployment_id = aws_apigatewayv2_deployment.deployment.id
#}
#
#resource "aws_lambda_permission" "lambda_permission_list" {
#  statement_id  = "allow_api_gateway"
#  action        = "lambda:InvokeFunction"
#  function_name = aws_lambda_function.list.function_name
#  principal     = "apigateway.amazonaws.com"
#
#  source_arn = "${aws_apigatewayv2_api.api_gateway.execution_arn}/*"
#}
#
#resource "aws_lambda_permission" "lambda_permission_upload_link" {
#  statement_id  = "allow_api_gateway"
#  action        = "lambda:InvokeFunction"
#  function_name = aws_lambda_function.upload_link.function_name
#  principal     = "apigateway.amazonaws.com"
#
#  source_arn = "${aws_apigatewayv2_api.api_gateway.execution_arn}/*"
#}
