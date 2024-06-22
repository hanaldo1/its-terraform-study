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
  source = "../vpc"

  prefix = "module1"
  vpc_cidr = "10.0.0.0/16"
}