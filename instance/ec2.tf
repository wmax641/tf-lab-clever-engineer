data "aws_ami" "lab_ami" {
  most_recent = true
  filter {
    name   = "name"
    values = ["lab-clueless-engineer-ami*"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_launch_template" "lab_instance" {
  name          = "${local.uniq_prefix}-launch-template"
  image_id      = data.aws_ami.lab_ami.image_id
  instance_type = "t3a.micro"
  iam_instance_profile {
    arn = aws_iam_instance_profile.lab_instance_profile.arn
  }
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }
  tag_specifications {
    resource_type = "instance"
    tags          = merge({ "Name" = "${local.uniq_prefix}" }, local.tags)
  }
  vpc_security_group_ids = [var.sg_id]
  tags                   = merge({ "Name" = "${local.uniq_prefix}" }, local.tags)
  user_data              = filebase64("${path.module}/files/bootstrap_instance.sh")
}

resource "aws_autoscaling_group" "lab_instance_asg" {
  name                = local.uniq_prefix
  vpc_zone_identifier = [var.subnet_id]
  desired_capacity    = 1
  max_size            = 1
  min_size            = 1

  launch_template {
    id      = aws_launch_template.lab_instance.id
    version = "$Latest"
  }
  tag {
    key                 = "Name"
    value               = local.uniq_prefix
    propagate_at_launch = false
  }
  #tag = merge({ "Name" = "${local.uniq_prefix}" }, local.tags)
}
