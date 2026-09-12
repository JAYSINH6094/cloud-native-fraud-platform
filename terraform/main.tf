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
  region = "ap-south-1"
}

resource "aws_vpc" "fraud_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "fraud-platform-vpc"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.fraud_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "fraud-public-subnet"
  }
}

resource "aws_internet_gateway" "fraud_igw" {
  vpc_id = aws_vpc.fraud_vpc.id

  tags = {
    Name = "fraud-platform-igw"
  }
}

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

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.fraud_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "fraud-private-subnet"
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

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.fraud_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "fraud-private-subnet-2"
  }
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.fraud_vpc.id

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

# ALB Security Group
resource "aws_security_group" "alb_sg" {
  name        = "fraud-alb-sg"
  description = "Security group for fraud platform ALB"
  vpc_id      = aws_vpc.fraud_vpc.id

  ingress {
    description = "Allow HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "fraud-alb-sg"
  }
}


# Application Security Group
resource "aws_security_group" "app_sg" {
  name        = "fraud-app-sg"
  description = "Security group for fraud application"
  vpc_id      = aws_vpc.fraud_vpc.id

  ingress {
    description     = "Allow API traffic from ALB"
    from_port       = 8000
    to_port         = 8000
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    description = "Allow outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "fraud-app-sg"
  }
}


# RDS Security Group
resource "aws_security_group" "rds_sg" {
  name        = "fraud-rds-sg"
  description = "Security group for MySQL RDS"
  vpc_id      = aws_vpc.fraud_vpc.id

  ingress {
    description     = "Allow MySQL from application"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id, "sg-08d8f3296eea9fb31"]
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
  password = "fraud_password"

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

resource "aws_iam_role" "ec2_role" {
  name = "fraud-platform-ec2-role"

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

  tags = {
    Name = "fraud-platform-ec2-role"
  }
}


resource "aws_iam_instance_profile" "ec2_profile" {
  name = "fraud-platform-ec2-profile"
  role = aws_iam_role.ec2_role.name
}


resource "aws_instance" "fraud_app" {
  ami           = "ami-0c0fd09cfe77b59dc"
  instance_type = "t3.micro"

  subnet_id = aws_subnet.public_subnet.id

  vpc_security_group_ids = [
    aws_security_group.app_sg.id
  ]

  iam_instance_profile = aws_iam_instance_profile.ec2_profile.name

  associate_public_ip_address = true

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y docker.io
              systemctl enable docker
              systemctl start docker
              EOF

  tags = {
    Name = "fraud-app-server"
  }
}

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# -------------------------
# Application Load Balancer
# -------------------------

resource "aws_lb" "fraud_alb" {
  name               = "fraud-platform-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets = [
    aws_subnet.public_subnet.id,
    aws_subnet.public_subnet_2.id
  ]

  tags = {
    Name = "fraud-platform-alb"
  }
}

resource "aws_lb_target_group" "fraud_api" {
  name     = "fraud-api-tg"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = aws_vpc.fraud_vpc.id

  health_check {
    path                = "/health"
    protocol            = "HTTP"
    port                = "8000"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
  }

  tags = {
    Name = "fraud-api-target-group"
  }
}

resource "aws_lb_target_group_attachment" "fraud_api" {
  target_group_arn = aws_lb_target_group.fraud_api.arn
  target_id        = aws_instance.fraud_app.id
  port             = 8000
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.fraud_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.fraud_api.arn
  }
}

output "alb_dns_name" {
  value = aws_lb.fraud_alb.dns_name
}