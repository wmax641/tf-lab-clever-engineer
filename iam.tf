data "aws_iam_policy_document" "lambda_assume_role_policy_doc" {
  statement {
    sid     = "LambdaAssumeRole${local.uniq_id}"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}
data "aws_iam_policy_document" "lambda_cloudwatch_policy_doc" {
  statement {
    sid     = "CreateCloudWatchLogGroup${local.uniq_id}"
    actions = ["logs:CreateLogGroup"]
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:*"
    ]
  }
  statement {
    sid = "PutCloudwatchLogs${local.uniq_id}"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = [
      "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/*"
    ]
  }
}

data "aws_iam_policy_document" "lambda_write_s3_policy_doc" {
  statement {
    sid = "Write2S3${local.uniq_id}"
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = [
      aws_s3_bucket.bucket.arn,
      "${aws_s3_bucket.bucket.arn}/*"
    ]
  }
}

data "aws_iam_policy_document" "lambda_read_s3_policy_doc" {
  statement {
    sid = "Write2S3${local.uniq_id}"
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]
    resources = [
      aws_s3_bucket.bucket.arn,
      "${aws_s3_bucket.bucket.arn}/*"
    ]
  }
}

data "aws_iam_policy_document" "read_ssm_param_policy_doc" {
  statement {
    sid = "ReadParam${local.uniq_id}"
    actions = [
      "ssm:GetParameter",
    ]
    resources = [
      aws_ssm_parameter.cred.arn
    ]
  }
}

resource "aws_iam_policy" "lambda_cloudwatch_policy" {
  name   = "${local.uniq_prefix}-lambda_cloudwatch_policy"
  policy = data.aws_iam_policy_document.lambda_cloudwatch_policy_doc.json
}
resource "aws_iam_policy" "lambda_write_s3_policy" {
  name   = "${local.uniq_prefix}-write_s3_policy"
  policy = data.aws_iam_policy_document.lambda_write_s3_policy_doc.json
}
resource "aws_iam_policy" "lambda_read_s3_policy" {
  name   = "${local.uniq_prefix}-read_s3_policy"
  policy = data.aws_iam_policy_document.lambda_read_s3_policy_doc.json
}
resource "aws_iam_policy" "read_ssm_param_policy" {
  name   = "${local.uniq_prefix}-read_ssm_param_policy"
  policy = data.aws_iam_policy_document.read_ssm_param_policy_doc.json
}

resource "aws_iam_role" "lambda_generate_s3_role" {
  name               = "LambdaGenerateS3Role-${local.uniq_prefix}"
  path               = "/service/"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy_doc.json
  managed_policy_arns = [
    aws_iam_policy.lambda_cloudwatch_policy.arn,
    aws_iam_policy.lambda_write_s3_policy.arn,
    aws_iam_policy.read_ssm_param_policy.arn,
  ]
  tags = merge({ "Name" = "LambdaGenerateS3Role-${local.uniq_prefix}" }, local.uniq_tags)
}

resource "aws_iam_role" "lambda_get_logs_role" {
  name               = "LambdaGetLogsRole-${local.uniq_prefix}"
  path               = "/service/"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy_doc.json
  managed_policy_arns = [
    aws_iam_policy.lambda_cloudwatch_policy.arn,
    aws_iam_policy.lambda_read_s3_policy.arn,
  ]
  tags = merge({ "Name" = "LambdaGetLogsRole-${local.uniq_prefix}" }, local.uniq_tags)
}
