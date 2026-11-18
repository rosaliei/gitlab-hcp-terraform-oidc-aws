output "customer_profile_private_key" {
  value     = module.customer_profile_key_pair.private_key_pem
  sensitive = true
}

output "account_private_key" {
  value     = module.account_key_pair.private_key_pem
  sensitive = true
}