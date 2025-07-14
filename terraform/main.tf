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
 
  tags = {
    Name = "private-subnet"
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
 
# Kubernetes Nodes (1 master, 2 workers) in private subnet
resource "aws_instance" "k8s_nodes" {
  count                  = 3
  ami                    = "ami-05ec1e5f7cfe5ef59" # Ubuntu 22.04 LTS
  instance_type          = "t2.medium"
  subnet_id              = aws_subnet.private.id
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.k8s_sg.id]
 
  tags = {
    Name = "k8s-node-${count.index}"
    Role = count.index == 0 ? "master" : "worker"
  }
}
abdelrahman@DESKTOP-832EB38:~/ansible-project/terraform-k8s$ ls
main.tf  outputs.tf  provider.tf  terraform.tfstate  terraform.tfstate.backup  variables.tf
abdelrahman@DESKTOP-832EB38:~/ansible-project/terraform-k8s$ cat outputs.tf
output "bastion_public_ip" {
  description = "Public IP of the Bastion host"
  value       = aws_instance.bastion.public_ip
}
 
output "k8s_private_ips" {
  description = "Private IPs of the Kubernetes nodes"
  value       = [for instance in aws_instance.k8s_nodes : instance.private_ip]
}
 
