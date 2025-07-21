# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
 
  tags = {
    Name = "k8s-vpc"
  }
}
 
# Subnets
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
 
  tags = {
    Name = "public-subnet"
  }
}
 
resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnet_cidr
  availability_zone = "us-east-1b"
  tags = {
    Name = "private-subnet"
  }
}
resource "aws_subnet" "private_2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnet_cidr_2
  availability_zone = "us-east-1a"  # for private
  tags = {
    Name = "private-subnet-2"
  }
}

 
# Internet Gateway for public subnet + NAT Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
 
  tags = {
    Name = "k8s-igw"
  }
}
 
# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  depends_on = [aws_internet_gateway.igw] # Ensure IGW is ready
 
  tags = {
    Name = "nat-eip"
  }
}
 
# NAT Gateway for private subnet internet access
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
 
  tags = {
    Name = "k8s-nat"
  }
}
 
# Public route table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
}
 
resource "aws_route" "public_internet_access" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}
 
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}
 
# Private route table using NAT
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id
}
 
resource "aws_route" "private_nat_route" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}
 
resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private_rt.id
}
resource "aws_route_table_association" "private_assoc_2" {
  subnet_id      = aws_subnet.private_2.id
  route_table_id = aws_route_table.private_rt.id
}
locals {
  worker_subnets = {
    "worker-1" = aws_subnet.private.id
    "worker-2" = aws_subnet.private_2.id
  }
}

# Security Groups
resource "aws_security_group" "bastion_sg" {
  name   = "bastion-sg"
  vpc_id = aws_vpc.main.id
 
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }
 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
 
resource "aws_security_group" "k8s_sg" {
  name   = "k8s-sg"
  vpc_id = aws_vpc.main.id
 
  # Allow all internal communication between k8s nodes
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }
 
  # Allow SSH only from bastion host
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }
 
  # Outbound to internet (via NAT)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
#import key pair name blue    
resource "aws_key_pair" "k8s_key" {
  key_name   = var.key_name
  public_key = var.public_key
}

# Bastion Host (Public Subnet)
resource "aws_instance" "bastion" {
  ami                    = "ami-05ec1e5f7cfe5ef59" # Ubuntu 22.04 LTS (verify region)
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
 
  tags = {
    Name = "bastion"
  }
}

resource "aws_instance" "worker_nodes" {
  for_each              = local.worker_subnets
  ami                   = "ami-05ec1e5f7cfe5ef59"
  instance_type         = "t2.medium"
  subnet_id             = each.value
  key_name              = var.key_name
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]

  tags = {
    Name = each.key
    Role = "worker"
  }
}

resource "aws_instance" "master_node" {
  ami                   = "ami-05ec1e5f7cfe5ef59"
  instance_type         = "t2.medium"
  subnet_id             = aws_subnet.private.id
  key_name              = var.key_name
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]

  tags = {
    Name = "master-node"
    Role = "master"
  }
}

#security group for alb
resource "aws_security_group" "alb_sg" {
  name   = "alb-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP from anywhere"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound traffic"
  }

  tags = {
    Name = "alb-sg"
  }
}

# ALB for Worker Node traffic (HTTP 31130)
resource "aws_lb" "k8s_alb" {
  name               = "k8s-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.private.id,
                       aws_subnet.public.id]
  depends_on = [aws_vpc.main]
  security_groups   = [aws_security_group.alb_sg.id]
  tags = {
    Name = "k8s-alb"
  }
}
resource "aws_lb_target_group" "worker_tg" {
  name        = "worker-tg"
  port        = 31130
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = aws_vpc.main.id

  health_check {
    protocol = "HTTP"
    port     = "31130"
    path     = "/"
    matcher  = "200"
  }

  tags = {
    Name = "tg-worker"
  }
}

# Listener for Worker Nodes
resource "aws_lb_listener" "worker_listener" {
  load_balancer_arn = aws_lb.k8s_alb.arn
  port              = 31130
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.worker_tg.arn
  }
}

# Attach workers to worker target group
resource "aws_lb_target_group_attachment" "worker_attachments" {
  for_each         = aws_instance.worker_nodes
  target_group_arn = aws_lb_target_group.worker_tg.arn
  target_id        = each.value.id
  port             = 31130
}
