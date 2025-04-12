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

#output "instance_id" {
#  value       = aws_instance.app_instance.id
#  description = "ID of the EC2 instance"
#}

#output "instance_public_ip" {
#  value       = aws_instance.app_instance.public_ip
#  description = "Public IP address of the EC2 instance"
#}

#output "instance_private_ip" {
#  value       = aws_instance.app_instance.private_ip
#  description = "Private IP address of the EC2 instance"
#}

output "security_group_id" {
  value       = aws_security_group.app_sg.id
  description = "ID of the security group attached to the EC2 instance"
}

#output "default_vpc_id" {
#  value       = data.aws_vpc.default.id
#  description = "ID of the default VPC"
#}

#output "default_subnet_id" {
#  value       = tolist(data.aws_subnets.default.ids)[0]
#  description = "ID of the default subnet used for the EC2 instance"
#}

output "rds_endpoint" {
  value       = aws_db_instance.postgres_db.endpoint
  description = "The connection endpoint for the RDS instance"
}

output "rds_db_name" {
  value       = aws_db_instance.postgres_db.db_name
  description = "The name of the database in the RDS instance"
}

output "s3_bucket_name" {
  value       = aws_s3_bucket.webapp_bucket.id
  description = "The name of the S3 bucket"
}

output "s3_bucket_arn" {
  value       = aws_s3_bucket.webapp_bucket.arn
  description = "The ARN of the S3 bucket"
}

output "db_security_group_id" {
  value       = aws_security_group.db_sg.id
  description = "The ID of the database security group"
}

#output "dev_name_servers" {
#  value = aws_route53_zone.dev.name_servers
#}

#output "demo_name_servers" {
#  value = aws_route53_zone.demo.name_servers
#}

#output "instance_ids" {
#  description = "IDs of instances launched by the Auto Scaling Group"
#  value       = aws_autoscaling_group.web_app_asg.instances
#}

output "load_balancer_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.web_app_lb.dns_name
}

output "kms_keys" {
  description = "KMS Keys ARNs"
  value = {
    ec2_key     = aws_kms_key.ec2_key.arn
    rds_key     = aws_kms_key.rds_key.arn
    s3_key      = aws_kms_key.s3_key.arn
    secrets_key = aws_kms_key.secrets_key.arn
  }
}

output "db_password_secret_arn" {
  description = "Secrets Manager ARN for DB password"
  value       = aws_secretsmanager_secret.db_password.arn
}

output "acm_dev_cert_arn" {
  description = "ACM Certificate ARN for Dev environment"
  value       = aws_acm_certificate.dev_cert.arn
}

output "generated_db_password" {
  value     = random_password.db_password.result
  sensitive = true
}




