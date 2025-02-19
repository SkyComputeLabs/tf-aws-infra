output "vpc_id" {
  value       = aws_vpc.main.id
  description = "VPC ID"
}

output "public_route_table_id" {
  value       = aws_route_table.public.id
  description = "Public Route Table IDs"
}

output "private_route_table_id" {
  value       = aws_route_table.private.id
  description = "Private Route Table IDs"
}

output "public_subnet_ids" {
  value       = aws_subnet.public[*].id
  description = "Public Subnet IDs"
}

output "private_subnet_ids" {
  value       = aws_subnet.private[*].id
  description = "Private Subnet IDs"
}

output "vpc_cidr" {
  value       = aws_vpc.main.cidr_block
  description = "VPC CIDR"
}

