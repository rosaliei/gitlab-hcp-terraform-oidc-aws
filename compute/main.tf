###############################################################################################################
### EC2 CREATION (jump host, nginx, RKE2 masters, RKE2 worker) ###
###############################################################################################################

locals {
  subnets = {
    public  = data.tfe_outputs.network.values.customer_profile_public_subnets
    private = data.tfe_outputs.network.values.customer_profile_private_subnets
  }
}

module "customer_profile_ec2_instance" {
  source = "terraform-aws-modules/ec2-instance/aws"

  providers = {
    aws = aws.singapore
  }

  for_each = var.customer_profile_ec2s
  name     = "instance-${each.key}"

  instance_type               = each.value.instance_type
  ami_ssm_parameter           = var.customer_profile_ec2_ami_ssm_parameter
  associate_public_ip_address = each.value.public_ip
  key_name                    = var.customer_profile_ec2_key_name
  monitoring                  = var.customer_profile_ec2_monitoring
  subnet_id                   = local.subnets[each.value.subnet][each.value.subnet_index]
  create_security_group       = false # use only the SGs from the security workspace
  vpc_security_group_ids      = compact([try(data.tfe_outputs.security.values[each.value.security_group], null)])

  root_block_device = {
    size = each.value.disk_size
    type = "gp3"
  }

  tags = {
    Terraform   = "true"
    Environment = "dev-customer-profile"
    Role        = each.value.role
  }
}

module "customer_profile_key_pair" {

  providers = {
    aws = aws.singapore
  }

  source  = "terraform-aws-modules/key-pair/aws"
  version = "3.0.1"

  key_name           = var.customer_profile_ec2_key_name
  create_private_key = true
}
