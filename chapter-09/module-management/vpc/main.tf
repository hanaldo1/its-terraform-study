resource "aws_vpc" "module" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name = "${var.prefix}-vpc"
  }
}