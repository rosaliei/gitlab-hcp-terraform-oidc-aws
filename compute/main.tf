###############################################################################################################
### CUSTOMER PROFILE EC2 CREATION ###
###############################################################################################################

module "customer_profile_ec2_instance" {
  source = "terraform-aws-modules/ec2-instance/aws"

  providers = {
    aws = aws.singapore
  }

  for_each = var.customer_profile_ec2_name
  name     = "instance-${each.key}"

  instance_type               = var.customer_profile_ec2_instance_type
  ami_ssm_parameter           = var.customer_profile_ec2_ami_ssm_parameter
  associate_public_ip_address = var.customer_profile_ec2_associate_public_ip_address
  key_name                    = var.customer_profile_ec2_key_name
  monitoring                  = var.customer_profile_ec2_monitoring
  subnet_id                   = data.tfe_outputs.network.values.public_subnets[0]

  tags = {
    Terraform   = "true"
    Environment = "dev-customer-profile"
  }
}

module "customer_profile_key_pair" {
  source  = "terraform-aws-modules/key-pair/aws"
  version = "3.0.1"

  key_name           = var.customer_profile_ec2_key_name
  create_private_key = true
}
###############################################################################################################
### ACCOUNT EC2 CREATION ###
###############################################################################################################
module "account_ec2_instance" {
  source = "terraform-aws-modules/ec2-instance/aws"

  providers = {
    aws = aws.singapore
  }

  for_each = var.account_ec2_name
  name     = "instance-${each.key}"

  instance_type               = var.account_ec2_instance_type
  ami_ssm_parameter           = var.account_ec2_ami_ssm_parameter
  associate_public_ip_address = var.account_ec2_associate_public_ip_address
  key_name                    = var.account_ec2_key_name
  monitoring                  = var.account_ec2_monitoring
  subnet_id                   = data.tfe_outputs.network.values.private_subnets[0]

  tags = {
    Terraform   = "true"
    Environment = "dev-account"
  }
}

module "account_key_pair" {
  source  = "terraform-aws-modules/key-pair/aws"
  version = "3.0.1"

  key_name           = var.account_ec2_key_name
  create_private_key = true
}