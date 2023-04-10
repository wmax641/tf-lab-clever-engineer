resource "aws_iam_role" "lab_instance_role" {
  name = "${local.uniq_prefix}-InstanceRole"

  managed_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore",
  ]

  inline_policy {
    name = "${local.uniq_prefix}-AccessInstanceSSMParamPolciy"

    policy = jsonencode({
      Version = "2012-10-17"
      Statement = [
        {
          Action = [
            "ssm:GetParameter",
          ]
          Effect = "Allow"
          Sid    = "ReadSSMforPrefix${local.uniq_id}"
          Resource = [
            "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter${local.ssm_param_path}/*"
          ]
        },
        {
          Action = [
            "ssm:PutParameter",
          ]
          Effect = "Allow"
          Sid    = "PutIPSSMforPrefix${local.uniq_id}"
          Resource = [
            "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter${local.ssm_param_path}/ip"
          ]
        },
      ]
    })
  }
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
  tags = merge({ "Name" = "${local.uniq_prefix}-InstanceRole" }, local.tags)
}
