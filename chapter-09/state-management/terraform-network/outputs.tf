output "subnet_id" {
  value = aws_subnet.hashicat.id
}

output "sg_id" {
  value = aws_security_group.hashicat.id
}