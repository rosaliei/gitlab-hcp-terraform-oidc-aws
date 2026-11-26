output "nginx_sg_id" {
  description = "Security group ID for the nginx load balancer"
  value       = module.nginx_security_group.id
}

output "customer_profile_jump_sg_id" {
  description = "Security group ID for the customer profile jump host"
  value       = module.customer_profile_jump_security_group.id
}

output "rke2_sg_id" {
  description = "Security group ID for the RKE2 nodes (masters + worker)"
  value       = aws_security_group.rke2.id
}
