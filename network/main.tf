module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.7.3" # pin to exact version - HashiCorp Recommendation

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

# DNS zone for kst-devops.com.
# After the first apply, copy the name_servers output into Namecheap (Domain -> Nameservers -> Custom DNS).
resource "aws_route53_zone" "main" {
  provider = aws.singapore
  name     = "kst-devops.com"
}
