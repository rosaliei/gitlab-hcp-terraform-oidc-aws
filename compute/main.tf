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
  vpc_security_group_ids      = [data.tfe_outputs.security.values[each.value.security_group]]

  # only nginx gets the IAM role (certbot -> Route53)
  iam_instance_profile = each.value.role == "nginx" ? data.tfe_outputs.security.values.nginx_instance_profile : null

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

###############################################################################################################
### DNS: rancher.kst-devops.com -> nginx public IP ###
###############################################################################################################

resource "aws_route53_record" "rancher" {
  provider = aws.singapore
  zone_id  = data.tfe_outputs.network.values.zone_id
  name     = "rancher.kst-devops.com"
  type     = "A"
  ttl      = 300
  records  = [module.ec2_instance["nginx"].public_ip]
}
