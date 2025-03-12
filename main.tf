# Configure the AWS provider with region and profil
provider "aws" {
  region = var.aws_region
  #profile = var.aws_profile
}

provider "google" {
  project = var.gcp_project_id
  region  = var.region
  zone    = var.zone
}

# Create a VPC with a specified CIDR block
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = var.vpc_name
  }
}

# Create an Internet Gateway and attach it to the VPC
resource "aws_internet_gateway" "main-igw" {
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

# Create a public route table and attach the Internet Gateway
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main-igw.id
  }
  tags = {
    Name = var.public_rt_name
  }
}

# Create a private route table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = var.private_rt_name
  }
}

# Associate public subnets with the public route table
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Associate private subnets with the private route table
resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Use the default VPC
data "aws_vpc" "default" {
  default = true
}

# Use the default subnets
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

#Security group configuration
resource "aws_security_group" "app_sg" {
  name        = "application-security-group"
  description = "Security group for web applications"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = var.app_port
    to_port     = var.app_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "application-security-group"
  }
}

# EC2 instance configuration
resource "aws_instance" "app_instance" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  vpc_security_group_ids = [aws_security_group.app_sg.id]
  subnet_id              = aws_subnet.public[0].id

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = var.root_volume_type
    delete_on_termination = var.root_volume_delete_on_termination
  }

  disable_api_termination = false

  tags = {
    Name = "web-application-instance"
  }
}

resource "google_compute_instance" "vm_instance" {
  project      = var.gcp_project_id
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.image
    }
  }

  network_interface {
    network = var.network
    access_config {
      // Ephemeral IP
    }
  }

  tags = ["http-server", "https-server", "app-server"]
}

resource "google_compute_firewall" "allow_http" {
  name    = "allow-http-from-internet"
  project = var.gcp_project_id
  network = "default" # Or your specific network

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]   # WARNING: For demonstration purposes only
  target_tags   = ["http-server"] # Apply rule to instances with this tag
}

resource "google_compute_firewall" "allow_https" {
  name    = "allow-https-from-internet"
  project = var.gcp_project_id
  network = "default" # Or your specific network

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]    # WARNING: For demonstration purposes only
  target_tags   = ["https-server"] # Apply rule to instances with this tag
}

resource "google_compute_firewall" "allow_custom_port" {
  name    = "allow-custom-port-from-internet"
  project = var.gcp_project_id
  network = "default" # Or your specific network

  allow {
    protocol = "tcp"
    ports    = [var.app_port] # Replace with your application port
  }

  source_ranges = ["0.0.0.0/0"]  # WARNING: For demonstration purposes only
  target_tags   = ["app-server"] # Apply rule to instances with this tag
}

