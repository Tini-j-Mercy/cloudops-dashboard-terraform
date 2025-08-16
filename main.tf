provider "aws" {
  region = var.aws_region
}

# VPC
resource "aws_vpc" "main_vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "cloudops-vpc"
  }
}

# Public subnets
resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.public_subnet_a
  availability_zone = var.az1
  map_public_ip_on_launch = true
  tags = { Name = "public-subnet-a" }
}

resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.public_subnet_b
  availability_zone = var.az2
  map_public_ip_on_launch = true
  tags = { Name = "public-subnet-b" }
}

# Private subnets
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.private_subnet_a
  availability_zone = var.az1
  tags = { Name = "private-subnet-a" }
}

resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.private_subnet_b
  availability_zone = var.az2
  tags = { Name = "private-subnet-b" }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id
  tags = { Name = "cloudops-igw" }
}

# NAT Gateways
resource "aws_eip" "nat_a" { vpc = true }
resource "aws_nat_gateway" "nat_a" {
  allocation_id = aws_eip.nat_a.id
  subnet_id     = aws_subnet.public_a.id
}

resource "aws_eip" "nat_b" { vpc = true }
resource "aws_nat_gateway" "nat_b" {
  allocation_id = aws_eip.nat_b.id
  subnet_id     = aws_subnet.public_b.id
}

# Route Tables
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "public-rt" }
}

resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_rt.id
}
resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table" "private_rt_a" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_a.id
  }
}

resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_rt_a.id
}

resource "aws_route_table" "private_rt_b" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_b.id
  }
}

resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private_rt_b.id
}

# Security Groups
resource "aws_security_group" "bastion_sg" {
  vpc_id = aws_vpc.main_vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }
  egress { from_port = 0; to_port = 0; protocol = "-1"; cidr_blocks = ["0.0.0.0/0"] }
  tags = { Name = "bastion-sg" }
}

resource "aws_security_group" "asg_sg" {
  vpc_id = aws_vpc.main_vpc.id
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }
  egress { from_port = 0; to_port = 0; protocol = "-1"; cidr_blocks = ["0.0.0.0/0"] }
  tags = { Name = "asg-sg" }
}

# Bastion Host
resource "aws_instance" "bastion" {
  ami           = var.ubuntu_ami
  instance_type = var.bastion_type
  subnet_id     = aws_subnet.public_a.id
  key_name      = var.key_name
  security_groups = [aws_security_group.bastion_sg.name]
  tags = { Name = "bastion" }
}

# Launch Template for ASG
resource "aws_launch_template" "asg_lt" {
  name_prefix   = "asg-lt-"
  image_id      = var.ubuntu_ami
  instance_type = var.asg_instance_type
  key_name      = var.key_name
  security_group_names = [aws_security_group.asg_sg.name]
  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install python3 -y
              mkdir -p /home/ubuntu/html
              cp /home/ubuntu/index.html /home/ubuntu/html/index.html
              cd /home/ubuntu/html
              nohup python3 -m http.server 8000 &
              EOF
}

# Auto Scaling Group
resource "aws_autoscaling_group" "asg" {
  vpc_zone_identifier = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  desired_capacity    = 2
  max_size            = 2
  min_size            = 2
  health_check_type   = "EC2"
  launch_template {
    id      = aws_launch_template.asg_lt.id
    version = "$Latest"
  }
}

# Application Load Balancer
resource "aws_lb" "alb" {
  name               = "cloudops-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]
}

resource "aws_lb_target_group" "tg" {
  name     = "cloudops-tg"
  port     = 8000
  protocol = "HTTP"
  vpc_id   = aws_vpc.main_vpc.id
  health_check {
    path                = "/"
    protocol            = "HTTP"
    interval            = 30
    unhealthy_threshold = 2
    healthy_threshold   = 2
  }
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

resource "aws_autoscaling_attachment" "asg_alb_attach" {
  autoscaling_group_name = aws_autoscaling_group.asg.name
  lb_target_group_arn    = aws_lb_target_group.tg.arn
}
