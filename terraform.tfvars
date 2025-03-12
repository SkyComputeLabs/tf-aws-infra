aws_region = "us-east-1"
#aws_profile = "User1"

vpc_cidr = "10.1.0.0/16"

public_subnet_cidrs  = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
private_subnet_cidrs = ["10.1.101.0/24", "10.1.102.0/24", "10.1.103.0/24"]

availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]

vpc_name        = "vpc1"
igw_name        = "main-igw"
public_rt_name  = "main-public-rt"
private_rt_name = "main-private-rt"

# New variables

ami_id        = "ami-0aca0bcf1557f67bc"
instance_type = "t2.micro"

app_port = 8080

root_volume_size                  = 25
root_volume_type                  = "gp2"
root_volume_delete_on_termination = true

gcp_project_id = "csye6225-dev-451900"
instance_name  = "csye6225-dev-instance"
region         = "us-east1"
machine_type   = "n1-standard-1"
zone           = "us-east1-b"
image          = "projects/debian-cloud/global/images/debian-10-buster-v20220406"



