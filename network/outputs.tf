################################################################################
# customer_profile_vpc (Singapore)
################################################################################
output "customer_profile_vpc_id" {
  description = "The ID of the customer_profile VPC"
  value       = module.customer_profile_vpc.vpc_id
}

output "customer_profile_vpc_cidr_block" {
  description = "The CIDR block of the customer_profile VPC"
  value       = module.customer_profile_vpc.vpc_cidr_block
}

output "customer_profile_public_subnets" {
  description = "List of IDs of public subnets in the customer_profile VPC"
  value       = module.customer_profile_vpc.public_subnets
}

output "customer_profile_private_subnets" {
  description = "List of IDs of private subnets in the customer_profile VPC"
  value       = module.customer_profile_vpc.private_subnets
}

################################################################################
# account_vpc (Tokyo)
################################################################################
output "account_vpc_id" {
  description = "The ID of the account VPC"
  value       = module.account_vpc.vpc_id
}

output "account_vpc_cidr_block" {
  description = "The CIDR block of the account VPC"
  value       = module.account_vpc.vpc_cidr_block
}

output "account_public_subnets" {
  description = "List of IDs of public subnets in the account VPC"
  value       = module.account_vpc.public_subnets
}

output "account_private_subnets" {
  description = "List of IDs of private subnets in the account VPC"
  value       = module.account_vpc.private_subnets
}
