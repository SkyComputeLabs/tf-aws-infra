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

variable "vpc_name"{
  type = string
  description = "Name for VPC"
}