locals {
  sid_suffix = "CluelessEngineerLab"
}

data "aws_iam_policy_document" "lambda_assume_role_policy_doc" {
  statement {
    sid     = "LambdaAssumeRole${local.sid_suffix}"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda_cloudwatch_policy_doc" {
  statement {
    sid     = "CreateCloudWatchLogGroup${local.sid_suffix}"
    actions = ["logs:CreateLogGroup"]
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
    ]
  }
  statement {
    sid = "PutCloudwatchLogs${local.sid_suffix}"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/*"
    ]
  }
}

data "aws_iam_policy_document" "read_all_ssm_param_policy_doc" {
  statement {
    sid = "ReadAllSSMfor${local.sid_suffix}"
    actions = [
      "ssm:GetParameter",
    ]
    resources = [
      "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${var.base_name}-*"
    ]
  }
}

data "aws_iam_policy_document" "terminate_instance_ec2_policy_doc" {
  statement {
    sid = "DescribeInstanceEC2For${local.sid_suffix}"
    actions = [
      "ec2:DescribeInstances",
    ]
    resources = [
      "*"
    ]
  }
  statement {
    sid = "TerminateInstanceEC2For${local.sid_suffix}"
    actions = [
      "ec2:TerminateInstances",
    ]
    resources = [
      "arn:aws:ec2:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:instance/*"
    ]
    condition {
      test     = "StringLike"
      variable = "aws:ResourceTag/uniq_prefix"
      values   = ["${var.base_name}-*"]
    }
  }
  statement {
    sid = "TerminateInstanceSSMFor${local.sid_suffix}"
    actions = [
      "ssm:GetParameter",
      "ssm:PutParameter",
    ]
    resources = [
      "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter/${var.base_name}-*"
    ]
  }
}

resource "aws_iam_policy" "read_all_ssm_param_policy" {
  name   = "${var.base_name}-read_all_ssm_param_policy"
  policy = data.aws_iam_policy_document.read_all_ssm_param_policy_doc.json
}
resource "aws_iam_policy" "lambda_cloudwatch_policy" {
  name   = "${var.base_name}-lambda_cloudwatch_policy"
  policy = data.aws_iam_policy_document.lambda_cloudwatch_policy_doc.json
}
resource "aws_iam_policy" "terminate_instance_ec2_policy" {
  name   = "${var.base_name}-termiante-instance-ec2-policy"
  policy = data.aws_iam_policy_document.terminate_instance_ec2_policy_doc.json
}

resource "aws_iam_role" "lambda_logs_role" {
  name               = "${var.base_name}-LambdaLogsRole"
  path               = "/service/"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy_doc.json
  managed_policy_arns = [
    aws_iam_policy.read_all_ssm_param_policy.arn,
    aws_iam_policy.lambda_cloudwatch_policy.arn,
  ]
  tags = merge({ "Name" = "${var.base_name}-LambdaLogsRole" }, var.common_tags)
}

resource "aws_iam_role" "lambda_server_role" {
  name               = "${var.base_name}-LambdaTerminateInstanceRole"
  path               = "/service/"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy_doc.json
  managed_policy_arns = [
    aws_iam_policy.terminate_instance_ec2_policy.arn,
    aws_iam_policy.lambda_cloudwatch_policy.arn,
  ]
  tags = merge({ "Name" = "${var.base_name}-LambdaTerminateInstancesRole" }, var.common_tags)
}
