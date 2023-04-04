provider "aws" {
  region = "ap-southeast-2"
}
provider "archive" {}

terraform {
  backend "local" {
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.61"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.4.3"
    }
  }
}
