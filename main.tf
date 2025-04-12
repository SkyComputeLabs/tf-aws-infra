terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Random suffix for unique resource names
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# VPC Infrastructure
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = var.vpc_name
  }
}

resource "aws_internet_gateway" "main_igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = var.igw_name
  }
}

# Create public subnets in different availability zones
resource "aws_subnet" "public" {
  count                   = length(var.public_subnet_cidrs)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-${count.index + 1}"
  }
}

# Create private subnets in different availability zones
resource "aws_subnet" "private" {
  count             = length(var.private_subnet_cidrs)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "private-subnet-${count.index + 1}"
  }
}

# Routing
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_igw.id
  }
  tags = {
    Name = var.public_rt_name
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = var.private_rt_name
  }
}

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Security Groups
resource "aws_security_group" "app_sg" {
  name        = "app-sg-${random_string.suffix.result}"
  description = "Application security group"
  vpc_id      = aws_vpc.main.id

  #ingress {
  #  description = "HTTP"
  #  from_port   = 80
  #  to_port     = 80
  #  protocol    = "tcp"
  #  cidr_blocks = ["0.0.0.0/0"]
  #}

  #ingress {
  #  description = "HTTPS"
  #  from_port   = 443
  #  to_port     = 443
  #  protocol    = "tcp"
  #  cidr_blocks = ["0.0.0.0/0"]
  #}

  #ingress {
  #  description = "SSH"
  #  from_port   = 22
  #  to_port     = 22
  #  protocol    = "tcp"
  #  cidr_blocks = ["0.0.0.0/0"]
  #}

  #ingress {
  #  description = "Spring Boot Application Port"
  #  from_port   = 8080
  #  to_port     = 8080
  #  protocol    = "tcp"
  #  cidr_blocks = ["0.0.0.0/0"]
  #}

  ingress {
    description     = "Allow traffic from Load Balancer on application port"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.load_balancer_sg.id]
  }

  ingress {
    description = "Allow SSH access for management"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.public_ip_address]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "app-sg-${random_string.suffix.result}"
  }
}

resource "aws_security_group" "db_sg" {
  name        = "db-sg-${random_string.suffix.result}"
  description = "Database security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "db-sg-${random_string.suffix.result}"
  }
}

resource "aws_security_group" "load_balancer_sg" {
  name        = "load-balancer-sg-${random_string.suffix.result}"
  description = "Security group for Load Balancer"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "Allow HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow HTTPS traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "load-balancer-sg-${random_string.suffix.result}"
  }
}

# IAM Configuration
resource "aws_iam_role" "webapp_role" {
  name = "webapp-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "rds_describe_params" {
  name        = "RDSDescribeParametersPolicy-${random_string.suffix.result}"
  description = "Allow describing RDS parameters"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "rds:DescribeDBParameters"
        Resource = "arn:aws:rds:us-east-2:842676014449:pg:rds-db-parameter-group"
      }
    ]
  })
}

resource "aws_iam_user" "dev" {
  name = "dev"
}

resource "aws_iam_user_policy_attachment" "user1_rds_describe_params" {
  user       = aws_iam_user.dev.name
  policy_arn = aws_iam_policy.rds_describe_params.arn
}

resource "aws_iam_policy" "essential_permissions" {
  name        = "EssentialTerraformPermissions"
  description = "Core permissions for Terraform operations"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "iam:*",
          "rds:*",
          "iam:GetRole",
          "iam:ListAttachedUserPolicies",
          "iam:CreatePolicy",
          "iam:AttachUserPolicy",
          "iam:PassRole",
          "iam:DetachRolePolicy"

        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "essential_perms" {
  user       = aws_iam_user.dev.name
  policy_arn = aws_iam_policy.essential_permissions.arn
}

resource "aws_iam_policy" "instance_profile_permissions" {
  name        = "InstanceProfilePermissions"
  description = "Permissions for managing IAM instance profiles"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "iam:GetInstanceProfile",
          "iam:CreateInstanceProfile",
          "iam:AddRoleToInstanceProfile",
          "iam:DetachRolePolicy"
        ],
        Resource = [
          "arn:aws:iam::842676014449:instance-profile/webapp-profile-*",
          "arn:aws:iam::842676014449:role/webapp-role-*"
        ]
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "instance_profile_perms" {
  user       = aws_iam_user.dev.name
  policy_arn = aws_iam_policy.instance_profile_permissions.arn
}

resource "aws_iam_policy" "passrole_policy" {
  name        = "PassRolePermissions"
  description = "Allows passing the webapp-role to AWS services"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "iam:PassRole",
        Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/webapp-role"
      }
    ]
  })
}

# Attach the policy to User1
resource "aws_iam_user_policy_attachment" "passrole_attach" {
  user       = "dev"
  policy_arn = aws_iam_policy.passrole_policy.arn
}


resource "aws_iam_instance_profile" "webapp_instance_profile" {
  name = "webapp-profile-${random_string.suffix.result}"
  role = aws_iam_role.webapp_role.name
}

resource "aws_iam_policy" "s3_access" {
  name        = "s3-access-policy-${random_string.suffix.result}"
  description = "S3 access policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "s3:GetObject",
        "s3:PutObject",
        "s3:ListBucket",
        "s3:DeleteObject"
      ]
      Resource = [
        "arn:aws:s3:::first-s3-bucket-6225",
        "arn:aws:s3:::first-s3-bucket-6225/*"
      ]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "attach_s3_access" {
  role       = aws_iam_role.webapp_role.name
  policy_arn = aws_iam_policy.s3_access.arn
}

resource "aws_iam_policy" "rds_access" {
  name        = "rds-access-policy-${random_string.suffix.result}"
  description = "RDS access policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "rds:Describe*",
        "rds:List*",
        "rds:Connect"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "attach_rds_access" {
  role       = aws_iam_role.webapp_role.name
  policy_arn = aws_iam_policy.rds_access.arn
}

# Create an A record for dev.shrutkeerti.me in its hosted zone
resource "aws_route53_record" "dev_alias_record" {
  zone_id = "Z04995731RXU7YGTUUIQD"

  name = "dev.shrutkeerti.me"
  type = "A"

  alias {
    # Replace with your ALB's DNS name and hosted zone ID
    name                   = aws_lb.web_app_lb.dns_name
    zone_id                = aws_lb.web_app_lb.zone_id
    evaluate_target_health = true
  }
}

#resource "aws_route53_record" "demo_alias_demo" {
#  zone_id = "Z013962252KPLVO70M0T"
#  name = "demo.webapp-cloud-metrics.com"
#  type = "A"

#  alias {
#    name = aws_lb.web_app_lb.dns_name
#    zone_id = aws_lb.web_app_lb.zone_id
#    evaluate_target_health = true
#  }
#}

# EC2 instance configuration
#resource "aws_instance" "app_instance" {
#  ami                    = var.ami_id
#  instance_type          = var.instance_type
#  vpc_security_group_ids = [aws_security_group.app_sg.id]
#  subnet_id              = aws_subnet.public[0].id
#  iam_instance_profile   = aws_iam_instance_profile.webapp_instance_profile.name
#
#
#  user_data = <<-EOF
#              #!/bin/bash
#              echo "DB_HOST=${aws_db_instance.postgres_db.endpoint}" >> /etc/environment
#              echo "DB_PORT=5432" >> /etc/environment
#              echo "DB_NAME=${aws_db_instance.postgres_db.db_name}" >> /etc/environment
#              echo "DB_USERNAME=${aws_db_instance.postgres_db.username}" >> /etc/environment
#              echo "DB_PASSWORD=${aws_db_instance.postgres_db.password}" >> /etc/environment
#              echo "S3_BUCKET_NAME=${aws_s3_bucket.webapp_bucket.bucket}" >> /etc/environment
#              echo "AWS_REGION=${var.aws_region}" >> /etc/environment
#              echo "APP_PORT=${var.app_port}" >> /etc/environment
#
#              # Configure and start CloudWatch Agent
#              sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
#                -a fetch-config \
#                -m ec2 \
#                -c file:/opt/aws/amazon-cloudwatch-agent/etc/cloudwatch-agent-config.json \ 
#                -s
#
#              if ! systemctl is-active --quiet amazon-cloudwatch-agent; then
#                echo "CloudWatch Agent failed to start" >&2
#                exit 1
#              fi  
#
#              sudo systemctl enable amazon-cloudwatch-agent
#              sudo systemctl start amazon-cloudwatch-agent
#
#              sudo systemctl restart csye6225.service
#
#              EOF
#
#  root_block_device {
#    volume_size           = var.root_volume_size
#    volume_type           = var.root_volume_type
#    delete_on_termination = var.root_volume_delete_on_termination
#  }
#
#  disable_api_termination = false
#
#  tags = {
#    Name = "web-application-instance"
#  }
#}

# EC2 instance Launch Template
resource "aws_launch_template" "web_app_template" {
  name        = "csye6225_asg"
  description = "Launch template for web application"

  image_id      = var.ami_id
  instance_type = var.instance_type

  key_name = var.key_name

  monitoring {
    enabled = true
  }

  # Attach IAM instance profile for permissions (e.g., S3, CloudWatch)
  iam_instance_profile {
    name = aws_iam_instance_profile.webapp_instance_profile.name
  }

  # Attach the application security group
  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [aws_security_group.app_sg.id]
    subnet_id                   = aws_subnet.public[0].id
  }

  # Root block device configuration
  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size           = var.root_volume_size
      volume_type           = var.root_volume_type
      delete_on_termination = var.root_volume_delete_on_termination
    }
  }

  # User Data Script 
  #user_data = base64encode(<<-EOF
  #            #!/bin/bash
  #            # Install AWS CLI v2 if needed
  #            sudo apt-get update
  #            sudo apt-get install -y unzip curl
  #
  #            # Install AWS CLI
  #            curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
  #            unzip awscliv2.zip
  #            sudo ./aws/install
  #
  #            # Retrieve DB Password from Secrets Manager
  #            DB_PASSWORD=$(aws secretsmanager get-secret-value --secret-id db-password --region ${var.aws_region} --query SecretString --output text)
  #
  #            echo "DB_HOST=${aws_db_instance.postgres_db.endpoint}" >> /etc/environment
  #            echo "DB_PORT=5432" >> /etc/environment
  #            echo "DB_NAME=${aws_db_instance.postgres_db.db_name}" >> /etc/environment
  #            echo "DB_USERNAME=${aws_db_instance.postgres_db.username}" >> /etc/environment
  #            #echo "DB_PASSWORD=${aws_db_instance.postgres_db.password}" >> /etc/environment
  #            echo "DB_PASSWORD=$DB_PASSWORD" >> /etc/environment
  #            echo "S3_BUCKET_NAME=${aws_s3_bucket.webapp_bucket.bucket}" >> /etc/environment
  #            echo "AWS_REGION=${var.aws_region}" >> /etc/environment
  #            echo "APP_PORT=${var.app_port}" >> /etc/environment
  #
  #            # Configure and start CloudWatch Agent
  #            sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
  #              -a fetch-config \
  #              -m ec2 \
  #              -c file:/opt/aws/amazon-cloudwatch-agent/etc/cloudwatch-agent-config.json \
  #              -s
  #
  #            if ! systemctl is-active --quiet amazon-cloudwatch-agent; then
  #              echo "CloudWatch Agent failed to start" >&2
  #              exit 1
  #            fi  
  #
  #            sudo systemctl enable amazon-cloudwatch-agent
  #            sudo systemctl start amazon-cloudwatch-agent
  #
  #            sudo systemctl restart csye6225.service 
  #            EOF
  #)

  user_data = base64encode(templatefile("${path.module}/userdata.sh.tpl", {
    db_host                   = aws_db_instance.postgres_db.endpoint
    db_name                   = aws_db_instance.postgres_db.db_name
    db_username               = aws_db_instance.postgres_db.username
    s3_bucket                 = aws_s3_bucket.webapp_bucket.bucket
    aws_region                = var.aws_region
    app_port                  = var.app_port
    db_password_secret_name   = aws_secretsmanager_secret.db_password.name
    email_service_secret_name = aws_secretsmanager_secret.email_service_secret.name
  }))

  tags = {
    Name = "WebAppInstance"
  }
}

# Auto Scaling Groups
resource "aws_autoscaling_group" "web_app_asg" {
  desired_capacity = var.desired_capacity
  min_size         = var.min_size
  max_size         = var.max_size
  default_cooldown = 60

  launch_template {
    id      = aws_launch_template.web_app_template.id
    version = "$Latest"
  }

  vpc_zone_identifier = aws_subnet.public[*].id

  health_check_type         = "EC2"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "WebAppInstance"
    propagate_at_launch = true
  }

  target_group_arns = [aws_lb_target_group.web_app_tg.arn]

  lifecycle {
    ignore_changes = [desired_capacity]
  }
}

resource "aws_autoscaling_policy" "scale_up_policy" {
  name                   = "scale_up_policy"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = aws_autoscaling_group.web_app_asg.name

  metric_aggregation_type = "Average"
}

# CloudWatch Alarm for Scale Up
resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "HighCPUUtilization-AutoScaleUp"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 30
  statistic           = "Average"
  threshold           = 30

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_app_asg.name
  }

  alarm_description = "This metric monitors EC2 CPU utilization for scale up"
  alarm_actions     = [aws_autoscaling_policy.scale_up_policy.arn]
}

resource "aws_autoscaling_policy" "scale_down_policy" {
  name                   = "scale_down_policy"
  scaling_adjustment     = -1
  adjustment_type        = "ChangeInCapacity"
  autoscaling_group_name = aws_autoscaling_group.web_app_asg.name

  metric_aggregation_type = "Average"
}

# CloudWatch Alarm for Scale Down
resource "aws_cloudwatch_metric_alarm" "cpu_low" {
  alarm_name          = "LowCPUUtilization-AutoScaleDown"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 30
  statistic           = "Average"
  threshold           = 10

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.web_app_asg.name
  }

  alarm_description = "This metric monitors EC2 CPU utilization for scale down"
  alarm_actions     = [aws_autoscaling_policy.scale_down_policy.arn]
}

# Application Load Balancer
resource "aws_lb" "web_app_lb" {
  name               = "web-app-alb"
  load_balancer_type = "application"

  security_groups = [aws_security_group.load_balancer_sg.id]
  subnets         = aws_subnet.public[*].id

  enable_deletion_protection = false
  tags = {
    Name = "WebAppALB"
  }
}

resource "aws_lb_target_group" "web_app_tg" {
  name = "web-app-tg"

  port     = var.app_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  target_type = "instance"

  health_check {
    path                = "/healthz"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    protocol            = "HTTP"
    port                = var.app_port
  }

  tags = { Name = "WebAppTargetGroup" }
}

resource "aws_lb_listener" "web_app_listener" {
  load_balancer_arn = aws_lb.web_app_lb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_app_tg.arn
  }
}

resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.web_app_lb.arn
  port              = 443
  protocol          = "HTTPS"

  ssl_policy      = "ELBSecurityPolicy-2016-08"
  certificate_arn = aws_acm_certificate.dev_cert.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.web_app_tg.arn
  }
}

# RDS Configuration
resource "aws_db_subnet_group" "db_subnet_group" {
  name       = "db-subnet-${random_string.suffix.result}"
  subnet_ids = aws_subnet.private[*].id

  tags = {
    Name = "db-subnet-${random_string.suffix.result}"
  }
}

resource "aws_db_parameter_group" "db_params" {
  name   = "db-params-${random_string.suffix.result}"
  family = "postgres${var.db_engine_version}"

  parameter {
    name  = "log_connections"
    value = "1"
  }
}

resource "aws_kms_alias" "rds_key_alias" {
  name          = "alias/rds-key"
  target_key_id = aws_kms_key.rds_key.key_id
}

resource "aws_kms_alias" "ec2_key_alias" {
  name          = "alias/ec2-key"
  target_key_id = aws_kms_key.ec2_key.key_id
}

resource "aws_kms_alias" "s3_key_alias" {
  name          = "alias/s3-key"
  target_key_id = aws_kms_key.s3_key.key_id
}

resource "aws_kms_alias" "secrets_key_alias" {
  name          = "alias/secrets-key"
  target_key_id = aws_kms_key.secrets_key.key_id
}

# Create PostgreSQQL RDS instance
resource "aws_db_instance" "postgres_db" {
  identifier        = "postgres-instance"
  engine            = "postgres"
  engine_version    = var.db_engine_version
  instance_class    = var.db_instance_type
  allocated_storage = var.db_allocated_storage
  storage_type      = var.db_storage_type
  db_name           = var.db_name
  username          = var.db_username
  #password               = var.db_password
  password               = random_password.db_password.result
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  db_subnet_group_name   = aws_db_subnet_group.db_subnet_group.name
  # parameter_group_name   = aws_db_parameter_group.params_grp.name
  multi_az            = false
  publicly_accessible = false
  skip_final_snapshot = true
  depends_on          = [aws_kms_key.rds_key]

  storage_encrypted = true
  kms_key_id        = aws_kms_key.rds_key.arn

  tags = {
    Name = "PostgreSQL Database"
  }
}

# S3 Configuration
resource "aws_s3_bucket" "webapp_bucket" {
  bucket = var.s3_bucket_name

  force_destroy = true
}

resource "aws_s3_bucket_public_access_block" "webapp_bucket" {
  bucket = aws_s3_bucket.webapp_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# IAM Policy Attachment Permissions
resource "aws_iam_policy" "policy_attachment" {
  name        = "PolicyAttachment-${random_string.suffix.result}"
  description = "Allows attaching policies to users"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "iam:AttachUserPolicy"
      Resource = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/User1"
    }]
  })
}

resource "aws_iam_user_policy_attachment" "policy_attach" {
  user       = aws_iam_user.dev.name
  policy_arn = aws_iam_policy.policy_attachment.arn
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role_policy_attachment" "attach_cloudwatch_agent_policy" {
  role       = aws_iam_role.webapp_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_policy" "custom_cloudwatch_policy" {
  name        = "CustomCloudWatchPolicy-${random_string.suffix.result}"
  description = "Custom policy for CloudWatch logs and metrics"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_custom_cloudwatch_policy" {
  role       = aws_iam_role.webapp_role.name
  policy_arn = aws_iam_policy.custom_cloudwatch_policy.arn
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.webapp_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_secretsmanager_secret" "db_password" {
  name       = "db-password-${random_string.suffix.result}"
  kms_key_id = aws_kms_key.secrets_key.arn
}

resource "random_password" "db_password" {
  length  = 16
  special = true
}

resource "aws_secretsmanager_secret_version" "db_password_version" {
  secret_id     = aws_secretsmanager_secret.db_password.id
  secret_string = random_password.db_password.result
}

resource "aws_s3_bucket_server_side_encryption_configuration" "webapp_bucket_sse" {
  bucket = aws_s3_bucket.webapp_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = aws_kms_key.s3_key.arn
      sse_algorithm     = "aws:kms"
    }
  }
}

resource "aws_acm_certificate" "dev_cert" {
  domain_name       = "dev.shrutkeerti.me"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Random password for Email Service
resource "random_password" "email_service_password" {
  length  = 16
  special = true
}

# Secrets Manager secret for Email Service
resource "aws_secretsmanager_secret" "email_service_secret" {
  name       = "email-service-credentials"
  kms_key_id = aws_kms_key.secrets_key.arn
}

# Secrets Manager secret version (actual secret data)
resource "aws_secretsmanager_secret_version" "email_service_secret_version" {
  secret_id = aws_secretsmanager_secret.email_service_secret.id
  secret_string = jsonencode({
    username = "your-email@example.com" # replace with your sender email address
    password = random_password.email_service_password.result
  })
}

# EC2 KMS Key
resource "aws_kms_key" "ec2_key" {
  description         = "KMS key for EC2"
  enable_key_rotation = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowRootAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowUserAccessForEC2"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/User1"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
          "kms:ListKeyPolicies",
          "kms:GetKeyPolicy"
        ]
        Resource = "*"
      }
    ]
  })
}

# RDS KMS Key
resource "aws_kms_key" "rds_key" {
  description         = "KMS key for RDS"
  enable_key_rotation = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowRootAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowUserAccessForRDS"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/User1"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
          "kms:ListKeyPolicies",
          "kms:GetKeyPolicy"
        ]
        Resource = "*"
      }
    ]
  })
}

# S3 KMS Key
resource "aws_kms_key" "s3_key" {
  description         = "KMS key for S3 bucket"
  enable_key_rotation = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowRootAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowUserAccessForS3"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/User1"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
          "kms:ListKeyPolicies",
          "kms:GetKeyPolicy"
        ]
        Resource = "*"
      }
    ]
  })
}

# Secrets Manager KMS Key
resource "aws_kms_key" "secrets_key" {
  description         = "KMS key for Secrets Manager"
  enable_key_rotation = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowRootAccess"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "AllowUserAccessForSecretsManager"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/User1"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey",
          "kms:ListKeyPolicies",
          "kms:GetKeyPolicy"
        ]
        Resource = "*"
      }
    ]
  })
}



