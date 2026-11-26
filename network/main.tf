module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.7.3" # pin to exact version - HashiCorp Recommendation
  #   version = "~> 6.7.1" # >= 6.7.1, < 6.8.0 - accept patch releases within the same minior
  #   version = "~> 6.7" # >= 6.7.0, < 7.0.0 - accept minor and patch releases within the major version
  #   version = ">= 6.7.1" # Any later version, including new majors

  providers = {
    aws = aws.singapore
  }

  name = var.vpc_name
  cidr = var.vpc_cidr
  azs  = var.vpc_azs

  public_subnets     = var.vpc_public_subnets
  private_subnets    = var.vpc_private_subnets
  enable_nat_gateway = true # private subnets (RKE2 nodes) need internet to install packages
  single_nat_gateway = var.single_nat_gateway
}


# Renamed from customer_profile_vpc. Tells Terraform it is the same VPC (no destroy).
moved {
  from = module.customer_profile_vpc
  to   = module.vpc
}
