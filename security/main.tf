locals {
  # Security group IDs that tfvars can refer to by name (source_sg = "...")
  security_group_ids = {
    customer_profile_jump = module.customer_profile_jump_security_group.id
  }

  # Same rules as tfvars, but source_sg is swapped for the real security group ID
  nginx_ingress_rules = {
    for name, rule in var.nginx_ingress_rules :
    name => merge(rule, {
      referenced_security_group_id = rule.source_sg == null ? rule.referenced_security_group_id : local.security_group_ids[rule.source_sg]
    })
  }
}

module "nginx_security_group" {
  source = "terraform-aws-modules/security-group/aws"

  providers = {
    aws = aws.singapore
  }

  name        = var.nginx_sg_name
  description = var.nginx_sg_description
  vpc_id      = data.tfe_outputs.network.values.customer_profile_vpc_id

  ingress_rules = local.nginx_ingress_rules
  egress_rules  = var.nginx_egress_rules

  tags = {
    Environment = "customer_profile"
    ManagedBy   = "terraform"
  }
}

module "customer_profile_jump_security_group" {
  source = "terraform-aws-modules/security-group/aws"

  providers = {
    aws = aws.singapore
  }

  name          = var.customer_profile_jump_sg_name
  description   = var.customer_profile_jump_sg_description
  vpc_id        = data.tfe_outputs.network.values.customer_profile_vpc_id
  ingress_rules = var.customer_profile_jump_ingress_rules
  egress_rules  = var.customer_profile_jump_egress_rules

  tags = {
    Environment = "customer_profile"
  }
}
