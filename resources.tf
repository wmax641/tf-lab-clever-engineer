data "aws_region" "current" {}
data "aws_caller_identity" "current" {}
data "aws_availability_zones" "available" {
  state = "available"
}

# # # # # VPC # # # # #

resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = merge({ "Name" = "${var.base_name}-vpc" }, var.common_tags)
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags   = merge({ "Name" = "${var.base_name}-igw" }, var.common_tags)
}

resource "aws_subnet" "subnet_public" {
  vpc_id                  = aws_vpc.vpc.id
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true
  cidr_block              = cidrsubnet(aws_vpc.vpc.cidr_block, 1, 0)
  tags                    = merge({ "Name" = "${var.base_name}-public-subnet" }, var.common_tags)
}
resource "aws_subnet" "subnet_private" {
  vpc_id            = aws_vpc.vpc.id
  availability_zone = data.aws_availability_zones.available.names[0]
  cidr_block        = cidrsubnet(aws_vpc.vpc.cidr_block, 1, 1)
  tags              = merge({ "Name" = "${var.base_name}-private_subnet" }, var.common_tags)
}

resource "aws_security_group" "vpc_endpoint_sg" {
  name   = "${var.base_name}-vpc_endpoint-sg"
  vpc_id = aws_vpc.vpc.id

  ingress {
    description = "inbound local"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.cidr_block]
  }
  egress {
    description = "outbound local"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.cidr_block]
  }
  tags = merge({ "Name" = "${var.base_name}-vpc_endpoint-sg" }, var.common_tags)
}

resource "aws_security_group" "instance_sg" {
  name        = "${var.base_name}-sg"
  description = "Allow SSH in"
  vpc_id      = aws_vpc.vpc.id

  ingress {
    description = "inbound ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "inbound http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "inbound https"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "inbound 1337"
    from_port   = 1337
    to_port     = 1337
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "outbound local"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.cidr_block]
  }
  #egress {
  #  description = "outbound everywhere"
  #  from_port   = 0
  #  to_port     = 0
  #  protocol    = "-1"
  #  cidr_blocks = ["0.0.0.0/0"]
  #}
  tags = merge({ "Name" = "${var.base_name}-sg" }, var.common_tags)
}

resource "aws_route_table" "route_table" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = merge({ "Name" = "${var.base_name}-route-table" }, var.common_tags)
}

resource "aws_route_table_association" "route_association_public" {
  subnet_id      = aws_subnet.subnet_public.id
  route_table_id = aws_route_table.route_table.id
}
resource "aws_route_table_association" "route_association_private" {
  subnet_id      = aws_subnet.subnet_private.id
  route_table_id = aws_route_table.route_table.id
}

# # # # # LAMBDA # # # # #

data "archive_file" "logs_lambda" {
  type             = "zip"
  source_file      = "${path.module}/lambda/logs.py"
  output_file_mode = "0666"
  output_path      = "${path.module}/lambda/logs.py.zip"
}
data "archive_file" "server_lambda" {
  type             = "zip"
  source_file      = "${path.module}/lambda/server.py"
  output_file_mode = "0666"
  output_path      = "${path.module}/lambda/server.py.zip"
}

resource "aws_lambda_function" "logs" {
  filename         = data.archive_file.logs_lambda.output_path
  function_name    = "${var.base_name}-logs-lambda"
  role             = aws_iam_role.lambda_logs_role.arn
  handler          = "logs.lambda_handler"
  timeout          = 4
  source_code_hash = filebase64sha256(data.archive_file.logs_lambda.output_path)
  runtime          = "python3.9"
  environment {
    variables = {
      base_param_path = "/${var.base_name}"
    }
  }
  tags = merge({ "Name" = "${var.base_name}-logs-lambda" }, var.common_tags)
}

resource "aws_lambda_function" "server" {
  filename         = data.archive_file.server_lambda.output_path
  function_name    = "${var.base_name}-server-lambda"
  role             = aws_iam_role.lambda_server_role.arn
  handler          = "server.lambda_handler"
  timeout          = 4
  source_code_hash = filebase64sha256(data.archive_file.server_lambda.output_path)
  runtime          = "python3.9"
  environment {
    variables = {
      base_param_path = "/${var.base_name}"
    }
  }
  tags = merge({ "Name" = "${var.base_name}-server-lambda" }, var.common_tags)
}

# # # # # API GATEWAY # # # # #

resource "aws_apigatewayv2_api" "api_gateway" {
  name          = "${var.base_name}-api-gateway"
  protocol_type = "HTTP"
  tags          = merge({ "Name" = "${var.base_name}-api-gateway" }, var.common_tags)
}

resource "aws_apigatewayv2_route" "logs" {
  api_id    = aws_apigatewayv2_api.api_gateway.id
  route_key = "GET /logs"

  target = "integrations/${aws_apigatewayv2_integration.logs.id}"
}
resource "aws_apigatewayv2_route" "server" {
  api_id    = aws_apigatewayv2_api.api_gateway.id
  route_key = "DELETE /server"

  target = "integrations/${aws_apigatewayv2_integration.server.id}"
}

resource "aws_apigatewayv2_integration" "logs" {
  api_id           = aws_apigatewayv2_api.api_gateway.id
  integration_type = "AWS_PROXY"

  connection_type      = "INTERNET"
  description          = "GET logs Lambda"
  integration_method   = "POST"
  integration_uri      = aws_lambda_function.logs.invoke_arn
  passthrough_behavior = "WHEN_NO_MATCH"
}
resource "aws_apigatewayv2_integration" "server" {
  api_id           = aws_apigatewayv2_api.api_gateway.id
  integration_type = "AWS_PROXY"

  connection_type      = "INTERNET"
  description          = "DELETE server Lambda"
  integration_method   = "POST"
  integration_uri      = aws_lambda_function.server.invoke_arn
  passthrough_behavior = "WHEN_NO_MATCH"
}

resource "aws_apigatewayv2_deployment" "deployment" {
  api_id      = aws_apigatewayv2_api.api_gateway.id
  description = "deployment!!"

  lifecycle {
    create_before_destroy = true
  }
  depends_on = [
    aws_apigatewayv2_route.logs,
  ]
}
resource "aws_apigatewayv2_stage" "v1" {
  api_id        = aws_apigatewayv2_api.api_gateway.id
  name          = "v1"
  auto_deploy   = true
  deployment_id = aws_apigatewayv2_deployment.deployment.id
}

resource "aws_lambda_permission" "lambda_permission_logs" {
  statement_id  = "allow_api_gateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.logs.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.api_gateway.execution_arn}/*"
}
resource "aws_lambda_permission" "lambda_permission_server" {
  statement_id  = "allow_api_gateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.server.function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_apigatewayv2_api.api_gateway.execution_arn}/*"
}

# # # # # VPC ENDPOINTS # # # # #
# These endpoints all have a count attribute. If var.instance_count is 0, then these endpoints
# won't be created to save money

resource "aws_vpc_endpoint" "ssm" {
  count        = var.instance_count > 0 ? 1 : 0
  vpc_id       = aws_vpc.vpc.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.ssm"
  dns_options {
    dns_record_ip_type = "ipv4"
  }
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
  subnet_ids          = [aws_subnet.subnet_public.id]
  vpc_endpoint_type   = "Interface"
  tags                = merge({ "Name" = "${var.base_name}-ssm" }, var.common_tags)
}
resource "aws_vpc_endpoint" "ssmmesssages" {
  count        = var.instance_count > 0 ? 1 : 0
  vpc_id       = aws_vpc.vpc.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.ssmmessages"
  dns_options {
    dns_record_ip_type = "ipv4"
  }
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
  subnet_ids          = [aws_subnet.subnet_public.id]
  vpc_endpoint_type   = "Interface"
  tags                = merge({ "Name" = "${var.base_name}-ssmmessages" }, var.common_tags)
}
resource "aws_vpc_endpoint" "ec2" {
  count        = var.instance_count > 0 ? 1 : 0
  vpc_id       = aws_vpc.vpc.id
  service_name = "com.amazonaws.${data.aws_region.current.name}.ec2"
  dns_options {
    dns_record_ip_type = "ipv4"
  }
  private_dns_enabled = true
  security_group_ids  = [aws_security_group.vpc_endpoint_sg.id]
  subnet_ids          = [aws_subnet.subnet_public.id]
  vpc_endpoint_type   = "Interface"
  tags                = merge({ "Name" = "${var.base_name}-ec2" }, var.common_tags)
}


# # # # # PARAMETERS # # # # #

resource "aws_ssm_parameter" "key" {
  name  = "${var.base_name}-key"
  type  = "String"
  value = var.key
  tags  = var.common_tags
}
