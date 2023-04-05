#data "aws_ami" "latest_amazon_linux" {
#  most_recent = true
#  owners      = ["amazon"]
#  filter {
#    name   = "name"
#    values = ["al2023-ami-202*-x86_64"]
#  }
#  filter {
#    name   = "root-device-type"
#    values = ["ebs"]
#  }
#  filter {
#    name   = "virtualization-type"
#    values = ["hvm"]
#  }
#  filter {
#    name   = "architecture"
#    values = ["x86_64"]
#  }
#}
#
#resource "aws_security_group" "host_sg" {
#  name        = "${local.uniq_prefix}-sg"
#  description = "Allow SSH in"
#  vpc_id      = aws_vpc.vpc.id
#
#  ingress {
#    description = "inbound ssh"
#    from_port   = 22
#    to_port     = 22
#    protocol    = "tcp"
#    cidr_blocks = ["0.0.0.0/0"]
#  }
#  egress {
#    description = "outbound local"
#    from_port   = 0
#    to_port     = 0
#    protocol    = "-1"
#    cidr_blocks = [var.cidr_block]
#  }
#  egress {
#    description = "outbound everywhere"
#    from_port   = 0
#    to_port     = 0
#    protocol    = "-1"
#    cidr_blocks = ["0.0.0.0/0"]
#  }
#  tags = merge({ "Name" = "${local.uniq_prefix}-sg" }, local.uniq_tags)
#}
#
