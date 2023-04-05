variable "base_name" {
  type    = string
  default = "lab-clueless-engineer"
}
variable "common_tags" {
  default = {
    "project" = "tf-lab-clueless-engineer"
  }
}
variable "username" {
  type    = string
  default = "seceng"
}
variable "cidr_block" {
  type    = string
  default = "10.13.37.0/24"
}
