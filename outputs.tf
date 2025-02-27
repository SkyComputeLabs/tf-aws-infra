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

# New outputs

output "instance_id" {
  value       = aws_instance.app_instance.id
  description = "ID of the EC2 instance"
}

output "instance_public_ip" {
  value       = aws_instance.app_instance.public_ip
  description = "Public IP address of the EC2 instance"
}

output "instance_private_ip" {
  value       = aws_instance.app_instance.private_ip
  description = "Private IP address of the EC2 instance"
}

output "security_group_id" {
  value       = aws_security_group.app_sg.id
  description = "ID of the security group attached to the EC2 instance"
}

output "default_vpc_id" {
  value       = data.aws_vpc.default.id
  description = "ID of the default VPC"
}

output "default_subnet_id" {
  value       = tolist(data.aws_subnets.default.ids)[0]
  description = "ID of the default subnet used for the EC2 instance"
}

output "instance_name" {
  description = "Name of the GCE instance"
  value       = google_compute_instance.vm_instance.name
}

output "instance_ip" {
  description = "Internal IP of the GCE instance"
  value       = google_compute_instance.vm_instance.network_interface[0].network_ip
}

output "instance_external_ip" {
  description = "External IP of the GCE instance"
  value       = google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip
}