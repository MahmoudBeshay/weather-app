variable "aws_region" {
  default = "us-east-1"
}
 
variable "vpc_cidr" {
  default = "10.0.0.0/16"
}
 
variable "public_subnet_cidr" {
  default = "10.0.1.0/24"
}
 
variable "private_subnet_cidr" {
  default = "10.0.2.0/24"
}
 
variable "key_name" {
  description = "Name of your EC2 Key Pair"
  default = "blue"
}
 
variable "allowed_ssh_cidr" {
  default = "196.132.53.186/32" # Replace this or pass at runtime
}
