output "bastion_public_ip" {
  description = "Public IP of the Bastion host"
  value       = aws_instance.bastion.public_ip
}
 output "worker_private_ips" {
  description = "Private IPs of the Kubernetes worker nodes"
  value       = [for instance in aws_instance.worker_nodes : instance.private_ip]
}
output "master_private_ip" {
  description = "Private IP of the Kubernetes master node"
  value       = aws_instance.master_node.private_ip
}
