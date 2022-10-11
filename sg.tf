resource "aws_security_group" "gtd_sg" {
  name = "allowAccessToGtdApp"
  vpc_id = local.vpc_id // TODO: get this somewhere, maybe the default vpc resource

  ingress {
    from_port = 3000
    to_port = 3000
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  // TODO: get vpc cidr block of default
    ipv6_cidr_blocks = ["::/0"]
  }
  
  ingress {
    from_port = 5432
    to_port = 5432
    protocol = "tcp"
    cidr_blocks = [aws_default_vpc.default.cidr_block]  // TODO: get vpc cidr block of default
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  lifecycle {
    create_before_destroy = true
  }

}
