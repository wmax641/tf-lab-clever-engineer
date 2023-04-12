resource "aws_ssm_parameter" "cred" {
  name  = "${local.ssm_param_path}/cred"
  type  = "String"
  value = random_string.cred.result
  tags  = local.tags
}
resource "aws_ssm_parameter" "username" {
  name  = "${local.ssm_param_path}/username"
  type  = "String"
  value = "user${random_integer.user_num.result}"
  tags  = local.tags
}
resource "aws_ssm_parameter" "ip" {
  name  = "${local.ssm_param_path}/ip"
  type  = "String"
  value = "1.3.3.7"
  tags  = local.tags
}
resource "aws_ssm_parameter" "terminated_datetime" {
  name  = "${local.ssm_param_path}/terminated-datetime"
  type  = "String"
  value = "13333337"
  tags  = local.tags
}
