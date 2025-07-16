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
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = "us-east-1a"

  tags = {
    Name = "private-subnet"
  }
}

resource "aws_subnet" "private2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidr2
  availability_zone = "us-east-1b"

  tags = {
    Name = "private-subnet-2"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "k8s-igw"
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "nat-eip"
  }
}

# NAT Gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  tags = {
    Name = "k8s-nat"
  }
}

# Route Tables
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

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "private2_rt" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "private-rt-2"
  }
}

resource "aws_route" "private_nat_route" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route" "private2_nat_route" {
  route_table_id         = aws_route_table.private2_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private2_assoc" {
  subnet_id      = aws_subnet.private2.id
  route_table_id = aws_route_table.private2_rt.id
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

  # Internal k8s traffic
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  # SSH from Bastion
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  # App traffic from ALB on NodePort 31130
  ingress {
    from_port   = 31130
    to_port     = 31130
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Open to world OR limit to ALB subnet CIDRs
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "master_security_group" {
  name   = "master-sg"
  vpc_id = aws_vpc.main.id

  # Allow Kube API traffic (from world or limit CIDRs)
  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # You can restrict to corporate IP or NLB subnet CIDRs
  }

  # Internal traffic from k8s nodes
  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.k8s_sg.id]
  }

  # SSH from Bastion
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

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
# Bastion Host
resource "aws_instance" "bastion" {
  ami                    = "ami-05ec1e5f7cfe5ef59"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.public.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

  tags = {
    Name = "bastion"
  }
}

# Master Node
resource "aws_instance" "master" {
  ami                    = "ami-05ec1e5f7cfe5ef59"
  instance_type          = "t2.medium"
  subnet_id              = aws_subnet.private.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.master_security_group.id]

  tags = {
    Name = "k8s-master"
    Role = "master"
  }
}

# Worker Nodes (Balanced across subnets)
resource "aws_instance" "worker" {
  count                  = 2
  ami                    = "ami-05ec1e5f7cfe5ef59"
  instance_type          = "t2.medium"
  subnet_id              = count.index == 0 ? aws_subnet.private.id : aws_subnet.private2.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]

  tags = {
    Name = "k8s-worker-${count.index}"
    Role = "worker"
  }
}
# NLB for Kubernetes API and Worker Node Traffic
resource "aws_lb" "k8s_nlb" {
  name               = "k8s-nlb"
  internal           = false
  load_balancer_type = "network"
  subnets            = [aws_subnet.public.id]

  tags = {
    Name = "k8s-nlb"
  }
}

# Target Group for Master Node - TCP 6443
resource "aws_lb_target_group" "master_tg" {
  name        = "master-tg"
  port        = 6443
  protocol    = "TCP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"

  health_check {
    port     = "6443"
    protocol = "TCP"
  }

  tags = {
    Name = "tg-master"
  }
}

# Listener for Master Node
resource "aws_lb_listener" "master_listener" {
  load_balancer_arn = aws_lb.k8s_nlb.arn
  port              = 6443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.master_tg.arn
  }
}

# Attach master instance to master target group
resource "aws_lb_target_group_attachment" "master_attachment" {
  target_group_arn = aws_lb_target_group.master_tg.arn
  target_id        = aws_instance.master.id
  port             = 6443
}

# ALB for Worker Node traffic (HTTP 31130)
resource "aws_lb" "k8s_alb" {
  name               = "k8s-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [aws_subnet.private2.id,
			aws_subnet.private.id]
  tags = {
    Name = "k8s-alb"
  }
}

# Target Group for Worker Nodes
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
  count            = 2
  target_group_arn = aws_lb_target_group.worker_tg.arn
  target_id        = aws_instance.worker[count.index].id
  port             = 31130
}

