output "customer_profile_ec2_sg_id" {
  description = "Security group ID for the customer profile EC2"
  value       = module.customer_profile_ec2_security_group.id
}

output "customer_profile_jump_sg_id" {
  description = "Security group ID for the customer profile jump host"
  value       = module.customer_profile_jump_security_group.id
}

output "account_sg_id" {
  description = "Security group ID for the account EC2 (Tokyo)"
  value       = module.account_security_group.id
}
