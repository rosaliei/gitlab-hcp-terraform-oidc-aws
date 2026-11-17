locals {
  # Security group IDs that tfvars can refer to by name (source_sg = "...")
  security_group_ids = {
    customer_profile_jump = module.customer_profile_jump_security_group.id
  }

  # Same rules as tfvars, but source_sg is swapped for the real security group ID
  customer_profile_ingress_rules = {
    for name, rule in var.customer_profile_ingress_rules :
    name => merge(rule, {
      referenced_security_group_id = rule.source_sg == null ? rule.referenced_security_group_id : local.security_group_ids[rule.source_sg]
    })
  }
}

module "customer_profile_ec2_security_group" {
  source = "terraform-aws-modules/security-group/aws"

  providers = {
    aws = aws.singapore
  }

  name        = var.customer_profile_sg_name
  description = var.customer_profile_sg_description
  vpc_id      = data.tfe_outputs.network.values.customer_profile_vpc_id

  ingress_rules = local.customer_profile_ingress_rules
  egress_rules  = var.customer_profile_egress_rules

  tags = {
    Environment = "customer_profile"
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

module "account_security_group" {
  source = "terraform-aws-modules/security-group/aws"

  # account VPC is in Tokyo
  providers = {
    aws = aws.tokyo
  }

  name          = var.account_sg_name
  description   = var.account_sg_description
  vpc_id        = data.tfe_outputs.network.values.account_vpc_id
  ingress_rules = var.account_ingress_rules
  egress_rules  = var.account_egress_rules

  tags = {
    Environment = "account"
  }
}
