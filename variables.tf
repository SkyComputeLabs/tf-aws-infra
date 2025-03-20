variable "aws_region" {
  type        = string
  description = "AWS region to deploy the resources"
}

variable "aws_profile" {
  type        = string
  description = "AWS CLI profile to use"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "igw_name" {
  type        = string
  description = "Name for the Internet Gateway"
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "CIDR block for the public subnets"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "CIDR block for the private subnets"
}

variable "availability_zones" {
  type        = list(string)
  description = "Availability zones for the subnets"
}

variable "public_rt_name" {
  type        = string
  description = "Name for the public route table"
}

variable "private_rt_name" {
  type        = string
  description = "Name for the private route table"
}

variable "vpc_name" {
  type        = string
  description = "Name for VPC"
}

# New variables

variable "ami_id" {
  type        = string
  description = "AMI ID for the EC2 instance"
}

variable "instance_type" {
  type        = string
  description = "Instance type for the EC2 instance"
}

variable "app_port" {
  type        = number
  description = "Port on which the application runs"
}

variable "root_volume_size" {
  type        = number
  description = "Size of the root volume in GB"
  default     = 25
}

variable "root_volume_type" {
  type        = string
  description = "Type of the root volume"
  default     = "gp2"
}

variable "root_volume_delete_on_termination" {
  type        = bool
  description = "Whether to delete the root volume on instance termination"
  default     = true
}

# variable "region" {
#   type        = string
#   description = "Region for the GCE instance"
#   default     = "us-central1"
# }

# variable "gcp_project_id" {
#   type        = string
#   description = "The GCP project ID"
# }

# variable "instance_name" {
#   type        = string
#   description = "Name of the GCE instance"
# }

# variable "machine_type" {
#   type        = string
#   description = "Machine type for the GCE instance"
#   default     = "n1-standard-1"
# }

# variable "zone" {
#   type        = string
#   description = "Zone for the GCE instance"
#   default     = "us-central1-a"
# }

# variable "image" {
#   type        = string
#   description = "Boot disk image for the GCE instance"
# }

# variable "network" {
#   type        = string
#   description = "Network for the GCE instance"
#   default     = "default"
# }

# PostgreSQL Database variables
variable "db_engine_version" {
  type        = string
  description = "Database engine version"
  default     = "17"
}

variable "db_instance_type" {
  type        = string
  description = "Instance type for the database"
  default     = "db.t3.micro"
}

variable "db_allocated_storage" {
  type        = number
  description = "Allocated storage size in GB"
  default     = 20
}

variable "db_storage_type" {
  type        = string
  description = "Storage type for the database"
  default     = "gp2"
}

variable "db_username" {
  type        = string
  description = "Database username"
  default     = "postgres"
}

variable "db_name" {
  type        = string
  description = "Database name"
  default     = "webapp"
}

variable "db_password" {
  type        = string
  description = "Database password"
  default     = "postgres"
}

variable "s3_bucket_name" {
  type        = string
  description = "Name of the S3 bucket"
  default     = "first-s3-bucket-6225"
}
