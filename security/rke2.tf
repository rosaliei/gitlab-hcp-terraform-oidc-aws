################################################################################
# RKE2 nodes (3 masters + 1 worker) all use this one security group
################################################################################

resource "aws_security_group" "rke2" {
  provider = aws.singapore

  name        = "rke2-node-sg"
  description = "RKE2 nodes"
  vpc_id      = data.tfe_outputs.network.values.vpc_id

  tags = {
    Environment = "open-innovation-ai"
    ManagedBy   = "terraform"
  }
}

# RKE2 node -> RKE2 node: everything (etcd, kube api, kubelet, CNI, ...)
resource "aws_vpc_security_group_ingress_rule" "rke2_from_rke2" {
  provider = aws.singapore

  security_group_id            = aws_security_group.rke2.id
  referenced_security_group_id = aws_security_group.rke2.id
  ip_protocol                  = "-1"
  description                  = "All traffic between RKE2 nodes"
}

# nginx -> RKE2 nodes
#   80, 443 = ingress controller
#   6443    = kubernetes api
#   9345    = rke2 join/register
resource "aws_vpc_security_group_ingress_rule" "rke2_from_nginx" {
  provider = aws.singapore
  for_each = toset(["80", "443", "6443", "9345"])

  security_group_id            = aws_security_group.rke2.id
  referenced_security_group_id = module.nginx_security_group.id
  ip_protocol                  = "tcp"
  from_port                    = each.value
  to_port                      = each.value
  description                  = "Port ${each.value} from nginx"
}

# jump host -> RKE2 nodes: SSH
resource "aws_vpc_security_group_ingress_rule" "rke2_ssh_from_jump" {
  provider = aws.singapore

  security_group_id            = aws_security_group.rke2.id
  referenced_security_group_id = module.jump_security_group.id
  ip_protocol                  = "tcp"
  from_port                    = 22
  to_port                      = 22
  description                  = "SSH from jump host"
}

# RKE2 nodes -> anywhere (download rke2, pull images)
resource "aws_vpc_security_group_egress_rule" "rke2_all_out" {
  provider = aws.singapore

  security_group_id = aws_security_group.rke2.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound"
}
