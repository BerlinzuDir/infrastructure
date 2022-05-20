output "public_subnet_ids" {
  description = "List of private subnet CIDR blocks"
  value       = [aws_subnet.public_1.id, aws_subnet.public_2.id]
}

output "id" {
  description = "Id of subnet"
  value = aws_vpc.decilo.id
}
