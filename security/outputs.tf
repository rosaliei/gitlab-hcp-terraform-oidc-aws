output "nginx_sg_id" {
  description = "Security group ID for the nginx load balancer"
  value       = module.nginx_security_group.id
}

output "jump_sg_id" {
  description = "Security group ID for the jump host"
  value       = module.jump_security_group.id
}

output "rke2_sg_id" {
  description = "Security group ID for the RKE2 nodes (masters + worker)"
  value       = aws_security_group.rke2.id
}
