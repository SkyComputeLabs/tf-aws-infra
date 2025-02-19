aws_region  = "us-east-1"
aws_profile = "dev"

vpc_cidr = "10.1.0.0/16"

public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
private_subnet_cidrs = ["10.1.101.0/24", "10.1.102.0/24", "10.1.103.0/24"]

availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

vpc_name = "vpc1"
igw_name        = "main-igw"
public_rt_name  = "main-public-rt"
private_rt_name = "main-private-rt"