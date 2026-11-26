output "customer_profile_private_key" {
  value     = module.customer_profile_key_pair.private_key_pem
  sensitive = true
}

output "public_ips" {
  description = "Public IPs (jump host, nginx)"
  value       = { for name, ec2 in module.customer_profile_ec2_instance : name => ec2.public_ip if ec2.public_ip != null && ec2.public_ip != "" }
}

output "private_ips" {
  description = "Private IPs of all servers"
  value       = { for name, ec2 in module.customer_profile_ec2_instance : name => ec2.private_ip }
}
