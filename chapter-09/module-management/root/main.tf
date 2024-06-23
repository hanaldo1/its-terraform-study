terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {}

module "vpc" {
#   source = "../vpc"

  # Github
  # source = "github.com/hanaldo1/its-terraform-study//chapter-09//module-management//vpc?ref=v0.0.1"

  # TFC Registry
  source  = "app.terraform.io/hanaldo-tf/module/aws"
  version = "0.0.1"

  prefix = "module1"
  vpc_cidr = "10.0.0.0/16"
}