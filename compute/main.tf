###############################################################################################################
### EC2 CREATION (jump host, nginx, RKE2 masters, RKE2 worker) ###
###############################################################################################################

locals {
  subnets = {
    public  = data.tfe_outputs.network.values.public_subnets
    private = data.tfe_outputs.network.values.private_subnets
  }
}

module "ec2_instance" {
  source = "terraform-aws-modules/ec2-instance/aws"

  providers = {
    aws = aws.singapore
  }

  for_each = var.ec2s
  name     = "instance-${each.key}"

  instance_type               = each.value.instance_type
  ami_ssm_parameter           = var.ami_ssm_parameter
  associate_public_ip_address = each.value.public_ip
  key_name                    = var.key_name
  monitoring                  = var.monitoring
  subnet_id                   = local.subnets[each.value.subnet][each.value.subnet_index]
  create_security_group       = false # use only the SGs from the security workspace
  vpc_security_group_ids      = compact([try(data.tfe_outputs.security.values[each.value.security_group], null)])

  root_block_device = {
    size = each.value.disk_size
    type = "gp3"
  }

  tags = {
    Terraform   = "true"
    Environment = "dev"
    Role        = each.value.role
  }
}

module "key_pair" {

  providers = {
    aws = aws.singapore
  }

  source  = "terraform-aws-modules/key-pair/aws"
  version = "3.0.1"

  key_name           = var.key_name
  create_private_key = true
}
