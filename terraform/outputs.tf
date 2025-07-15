output "bastion_public_ip" {
  description = "Public IP of the Bastion host"
  value       = aws_instance.bastion.public_ip
}
 
output "k8s_private_ips" {
  description = "Private IPs of the Kubernetes nodes"
  value       = [for instance in aws_instance.k8s_nodes : instance.private_ip]
}