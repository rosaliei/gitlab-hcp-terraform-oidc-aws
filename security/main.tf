locals {
  vpc_id = data.tfe_outputs.network.values.vpc_id
}

################################################################################
# JUMP HOST
#   in : 22 from internet
#   out: everything
################################################################################

resource "aws_security_group" "jump" {
  provider    = aws.singapore
  name        = "jump-sg"
  description = "Jump host"
  vpc_id      = local.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "jump_ssh" {
  provider          = aws.singapore
  security_group_id = aws_security_group.jump.id
  cidr_ipv4         = "0.0.0.0/0" # change to your own IP, e.g. "1.2.3.4/32"
  ip_protocol       = "tcp"
  from_port         = 22
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "jump_out" {
  provider          = aws.singapore
  security_group_id = aws_security_group.jump.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

################################################################################
# NGINX
#   in : 80, 443 from internet
#        22 from jump host
#   out: everything
################################################################################

resource "aws_security_group" "nginx" {
  provider    = aws.singapore
  name        = "nginx-sg"
  description = "nginx load balancer"
  vpc_id      = local.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "nginx_http" {
  provider          = aws.singapore
  security_group_id = aws_security_group.nginx.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "nginx_https" {
  provider          = aws.singapore
  security_group_id = aws_security_group.nginx.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "nginx_ssh_from_jump" {
  provider                     = aws.singapore
  security_group_id            = aws_security_group.nginx.id
  referenced_security_group_id = aws_security_group.jump.id
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
}

resource "aws_vpc_security_group_egress_rule" "nginx_out" {
  provider          = aws.singapore
  security_group_id = aws_security_group.nginx.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

################################################################################
# RKE2 NODES (3 masters + 1 worker)
#   in : everything from other RKE2 nodes
#        80, 443, 6443, 9345 from nginx
#        22 from jump host
#   out: everything
################################################################################

resource "aws_security_group" "rke2" {
  provider    = aws.singapore
  name        = "rke2-node-sg"
  description = "RKE2 nodes"
  vpc_id      = local.vpc_id
}

resource "aws_vpc_security_group_ingress_rule" "rke2_from_rke2" {
  provider                     = aws.singapore
  security_group_id            = aws_security_group.rke2.id
  referenced_security_group_id = aws_security_group.rke2.id
  ip_protocol                  = "-1"
}

resource "aws_vpc_security_group_ingress_rule" "rke2_from_nginx" {
  provider                     = aws.singapore
  for_each                     = toset(["80", "443", "6443", "9345"])
  security_group_id            = aws_security_group.rke2.id
  referenced_security_group_id = aws_security_group.nginx.id
  ip_protocol                  = "tcp"
  from_port                    = each.value
  to_port                      = each.value
}

resource "aws_vpc_security_group_ingress_rule" "rke2_ssh_from_jump" {
  provider                     = aws.singapore
  security_group_id            = aws_security_group.rke2.id
  referenced_security_group_id = aws_security_group.jump.id
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
}

resource "aws_vpc_security_group_egress_rule" "rke2_out" {
  provider          = aws.singapore
  security_group_id = aws_security_group.rke2.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}
