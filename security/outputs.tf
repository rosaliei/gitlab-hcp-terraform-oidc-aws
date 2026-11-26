output "jump_sg_id" {
  value = aws_security_group.jump.id
}

output "nginx_sg_id" {
  value = aws_security_group.nginx.id
}

output "rke2_sg_id" {
  value = aws_security_group.rke2.id
}
