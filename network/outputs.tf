################################################################################
# VPC (Singapore)
################################################################################
output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "The CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnets" {
  description = "List of IDs of public subnets in the VPC"
  value       = module.vpc.public_subnets
}

output "private_subnets" {
  description = "List of IDs of private subnets in the VPC"
  value       = module.vpc.private_subnets
}

output "zone_id" {
  description = "Route53 zone ID for kst-devops.com"
  value       = aws_route53_zone.main.zone_id
}

output "name_servers" {
  description = "Put these 4 into Namecheap as Custom DNS"
  value       = aws_route53_zone.main.name_servers
}
