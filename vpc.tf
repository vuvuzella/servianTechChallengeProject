// TODO: create own vpc
locals {
  vpc_id = "vpc-8ce7f7eb" 
}

data "aws_vpc" "default" {
  id = local.vpc_id
}

data "aws_subnets" "default" {
  filter {
    name = "vpc-id"
    values = [local.vpc_id]
  }
}

// TODO: create own security group with allow traffic
data "aws_security_groups" "default" {
  filter {
    name = "vpc-id"
    values = [local.vpc_id]
  }
}
