terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }

  required_version = ">= 1.5.0"
}

provider "aws" {
  region = var.aws_region
}

# -------------------------
# VPC
# -------------------------

resource "aws_vpc" "fraud_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "fraud-platform-vpc"
  }
}

# -------------------------
# Public Subnets
# -------------------------

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.fraud_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "fraud-public-subnet"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.fraud_vpc.id
  cidr_block              = "10.0.3.0/24"
  availability_zone       = "ap-south-1b"
  map_public_ip_on_launch = true

  tags = {
    Name = "fraud-public-subnet-2"
  }
}

# -------------------------
# Private Subnets
# -------------------------

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.fraud_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "fraud-private-subnet"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.fraud_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "fraud-private-subnet-2"
  }
}

# -------------------------
# Internet Gateway
# -------------------------

resource "aws_internet_gateway" "fraud_igw" {
  vpc_id = aws_vpc.fraud_vpc.id

  tags = {
    Name = "fraud-platform-igw"
  }
}

# -------------------------
# Public Route Table
# -------------------------

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.fraud_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.fraud_igw.id
  }

  tags = {
    Name = "fraud-public-route-table"
  }
}

resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_route_table_association" "public_subnet_association_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_route_table.id
}

# -------------------------
# NAT Gateway
# -------------------------

resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "fraud-nat-eip"
  }
}

resource "aws_nat_gateway" "fraud_nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet.id

  depends_on = [
    aws_internet_gateway.fraud_igw
  ]

  tags = {
    Name = "fraud-platform-nat"
  }
}

# -------------------------
# Private Route Table
# -------------------------

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.fraud_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.fraud_nat.id
  }

  tags = {
    Name = "fraud-private-route-table"
  }
}

resource "aws_route_table_association" "private_subnet_association" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_route_table.id
}

resource "aws_route_table_association" "private_subnet_association_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_route_table.id
}

# -------------------------
# RDS Security Group
# -------------------------

resource "aws_security_group" "rds_sg" {
  name        = "fraud-rds-sg"
  description = "Security group for MySQL RDS"
  vpc_id      = aws_vpc.fraud_vpc.id

  ingress {
    description = "Allow MySQL from EKS private subnets"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"

    cidr_blocks = [
      aws_subnet.private_subnet.cidr_block,
      aws_subnet.private_subnet_2.cidr_block
    ]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "fraud-rds-sg"
  }
}

# -------------------------
# RDS Subnet Group
# -------------------------

resource "aws_db_subnet_group" "fraud_db_subnet_group" {
  name = "fraud-db-subnet-group"

  subnet_ids = [
    aws_subnet.private_subnet.id,
    aws_subnet.private_subnet_2.id
  ]

  tags = {
    Name = "fraud-db-subnet-group"
  }
}

# -------------------------
# RDS MySQL
# -------------------------

resource "aws_db_instance" "fraud_mysql" {
  identifier = "fraud-mysql"

  engine         = "mysql"
  engine_version = "8.0"

  instance_class        = "db.t4g.micro"
  allocated_storage     = 20
  max_allocated_storage = 20
  storage_type          = "gp3"

  db_name  = "fraud_db"
  username = "fraud_user"
  password = var.db_password

  db_subnet_group_name = aws_db_subnet_group.fraud_db_subnet_group.name

  vpc_security_group_ids = [
    aws_security_group.rds_sg.id
  ]

  publicly_accessible     = false
  multi_az                = false
  skip_final_snapshot     = true
  deletion_protection     = false
  backup_retention_period = 0

  tags = {
    Name = "fraud-mysql"
  }
}

# -------------------------
# ECR Repositories
# -------------------------

resource "aws_ecr_repository" "fraud_api" {
  name                 = "fraud-api"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "fraud-api"
  }
}

resource "aws_ecr_repository" "fraud_engine" {
  name                 = "fraud-engine"
  image_tag_mutability = "IMMUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "fraud-engine"
  }
}