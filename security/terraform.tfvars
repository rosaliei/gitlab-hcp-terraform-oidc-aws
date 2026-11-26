################################################################################
# nginx security group (load balancer in front of RKE2)
################################################################################

nginx_sg_name        = "nginx-sg"
nginx_sg_description = "nginx - HTTP/HTTPS from public, SSH from jump host only"

# Public -> nginx: port 80 and 443
# Jump host -> nginx: port 22
nginx_ingress_rules = {
  http_from_internet = {
    description = "HTTP from internet"
    cidr_ipv4   = "0.0.0.0/0"
    ip_protocol = "tcp"
    from_port   = 80
    to_port     = 80
  }

  https_from_internet = {
    description = "HTTPS from internet"
    cidr_ipv4   = "0.0.0.0/0"
    ip_protocol = "tcp"
    from_port   = 443
    to_port     = 443
  }

  ssh_from_jump = {
    description = "SSH from jump host"
    source_sg   = "jump" # resolved to the jump SG ID in main.tf
    ip_protocol = "tcp"
    from_port   = 22
    to_port     = 22
  }
}

# nginx -> anywhere (RKE2 nodes, internet)
nginx_egress_rules = {
  all_to_internet = {
    description = "Allow all outbound"
    cidr_ipv4   = "0.0.0.0/0"
    ip_protocol = "-1"
  }
}

################################################################################
# JUMP security group
################################################################################

jump_sg_name        = "jump-sg"
jump_sg_description = "Jump host - SSH from public"

# Public -> jump host: SSH (22) only
# Tip: replace 0.0.0.0/0 with your office/home IP (e.g. "203.0.113.10/32") to lock it down.
jump_ingress_rules = {
  ssh_from_internet = {
    description = "SSH from internet"
    cidr_ipv4   = "0.0.0.0/0"
    ip_protocol = "tcp"
    from_port   = 22
    to_port     = 22
  }
}

# Jump host -> anywhere (internet, nginx, RKE2 nodes): allow all outbound
jump_egress_rules = {
  all_to_internet = {
    description = "Allow all outbound to internet"
    cidr_ipv4   = "0.0.0.0/0"
    ip_protocol = "-1"
  }
}
