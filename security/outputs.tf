output "jump_sg_id" {
  value = aws_security_group.jump.id
}

output "nginx_sg_id" {
  value = aws_security_group.nginx.id
}

output "rke2_sg_id" {
  value = aws_security_group.rke2.id
}

output "nginx_instance_profile" {
  value = aws_iam_instance_profile.nginx.name
}
