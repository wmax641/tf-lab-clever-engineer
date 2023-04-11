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
  name          = "${var.prisma_base_name}-launch-template"
  image_id      = data.aws_ami.lab_ami.image_id
  instance_type = "t2.micro"
  iam_instance_profile {
    arn = aws_iam_instance_profile.lab_instance_profile.arn
  }
  block_device_mappings {
    device_name = "/dev/sda1"
    ebs {
      volume_size = 8
    }
  }
  tag_specifications {
    resource_type = "instance"
    tags          = merge({ "Name" = "${local.uniq_prefix}" }, local.tags)
  }
  vpc_security_group_ids = [var.sg_id]
  tags          = merge({ "Name" = "${local.uniq_prefix}" }, local.tags)
  user_data              = filebase64("${path.module}/files/defender_bootstrap.sh")
}
