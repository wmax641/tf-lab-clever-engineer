variable "base_name" {
  type = string
}
variable "vpc_id" {
  type        = string
  description = "aws_vpc.id of the VPC the victim server resides in"
}
variable "subnet_id" {
  type        = string
  description = "aws_subnet.id of the subnet the victim server resides in"
}
variable "common_tags" {
}
