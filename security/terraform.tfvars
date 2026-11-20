################################################################################
# customer_profile EC2 security group
################################################################################

customer_profile_sg_name        = "customer-profile-ec2-sg"
customer_profile_sg_description = "Customer profile EC2 - HTTPS from public, SSH from jump host only"

# Public -> customer profile EC2: port 443 only
# Jump host -> customer profile EC2: port 22 only
customer_profile_ingress_rules = {
  https_from_internet = {
    description = "HTTPS from internet"
    cidr_ipv4   = "0.0.0.0/0"
    ip_protocol = "tcp"
    from_port   = 443
    to_port     = 443
  }

  ssh_from_jump = {
    description = "SSH from customer profile jump host"
    source_sg   = "customer_profile_jump" # resolved to the jump SG ID in main.tf
    ip_protocol = "tcp"
    from_port   = 22
    to_port     = 22
  }

  # KAN-4 TEST ONLY: OPA should block SSH from internet
  ssh_from_internet = {
    description = "SSH from internet (OPA test)"
    cidr_ipv4   = "0.0.0.0/0"
    ip_protocol = "tcp"
    from_port   = 22
    to_port     = 22
  }
}

# Customer profile EC2 -> internet: allow all outbound
customer_profile_egress_rules = {
  all_to_internet = {
    description = "Allow all outbound to internet"
    cidr_ipv4   = "0.0.0.0/0"
    ip_protocol = "-1"
  }
}

################################################################################
# customer_profile JUMP security group
################################################################################

customer_profile_jump_sg_name        = "customer-profile-jump-sg"
customer_profile_jump_sg_description = "Customer profile jump host - SSH from public"

# Public -> jump host: SSH (22) only
# Tip: replace 0.0.0.0/0 with your office/home IP (e.g. "203.0.113.10/32") to lock it down.
customer_profile_jump_ingress_rules = {
  ssh_from_internet = {
    description = "SSH from internet"
    cidr_ipv4   = "0.0.0.0/0"
    ip_protocol = "tcp"
    from_port   = 22
    to_port     = 22
  }
}

# Jump host -> internet (and therefore -> customer profile EC2): allow all outbound
customer_profile_jump_egress_rules = {
  all_to_internet = {
    description = "Allow all outbound to internet"
    cidr_ipv4   = "0.0.0.0/0"
    ip_protocol = "-1"
  }
}

################################################################################
# account security group (Tokyo)
################################################################################

account_sg_name        = "account-sg"
account_sg_description = "Account - HTTPS from customer profile VPC only"

# customer_profile (Singapore) -> account: port 443 only.
# Cross-region security group references are not supported by AWS,
# so the customer_profile VPC CIDR is used as the source.
account_ingress_rules = {
  https_from_customer_profile = {
    description = "HTTPS from customer profile VPC"
    cidr_ipv4   = "10.0.0.0/16"
    ip_protocol = "tcp"
    from_port   = 443
    to_port     = 443
  }
}

# Account -> internet: allow all outbound
account_egress_rules = {
  all_to_internet = {
    description = "Allow all outbound to internet"
    cidr_ipv4   = "0.0.0.0/0"
    ip_protocol = "-1"
  }
}
