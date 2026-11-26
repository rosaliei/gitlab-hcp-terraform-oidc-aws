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
#   in : 80, 443, 6443 from internet
#        6443, 9345 from RKE2 nodes
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

# Internet -> nginx: Kubernetes API (api.kst-devops.com:6443). kubectl still needs the kubeconfig cert.
resource "aws_vpc_security_group_ingress_rule" "nginx_api" {
  provider          = aws.singapore
  security_group_id = aws_security_group.nginx.id
  cidr_ipv4         = "0.0.0.0/0" # change to your own IP, e.g. "1.2.3.4/32"
  ip_protocol       = "tcp"
  from_port         = 6443
  to_port           = 6443
}

resource "aws_vpc_security_group_ingress_rule" "nginx_ssh_from_jump" {
  provider                     = aws.singapore
  security_group_id            = aws_security_group.nginx.id
  referenced_security_group_id = aws_security_group.jump.id
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
}

# RKE2 nodes -> nginx: kube api (6443) and rke2 join (9345)
resource "aws_vpc_security_group_ingress_rule" "nginx_from_rke2" {
  provider                     = aws.singapore
  for_each                     = toset(["6443", "9345"])
  security_group_id            = aws_security_group.nginx.id
  referenced_security_group_id = aws_security_group.rke2.id
  ip_protocol                  = "tcp"
  from_port                    = each.value
  to_port                      = each.value
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
#        30080 from nginx (Istio ingress gateway NodePort)
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
  for_each                     = toset(["80", "443", "6443", "9345", "30080"])
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

################################################################################
# NGINX IAM ROLE
#   lets certbot on nginx add the _acme-challenge TXT record in Route53
#   (only in the kst-devops.com zone)
################################################################################

resource "aws_iam_role" "nginx" {
  provider = aws.singapore
  name     = "nginx-certbot"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "nginx_route53" {
  provider = aws.singapore
  name     = "route53-certbot"
  role     = aws_iam_role.nginx.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["route53:ListHostedZones", "route53:GetChange"]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "route53:ChangeResourceRecordSets"
        Resource = "arn:aws:route53:::hostedzone/${data.tfe_outputs.network.values.zone_id}"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "nginx" {
  provider = aws.singapore
  name     = "nginx-certbot"
  role     = aws_iam_role.nginx.name
}
