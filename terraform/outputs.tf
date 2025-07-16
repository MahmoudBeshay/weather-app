output "bastion_public_ip" {
  description = "Public IP of the Bastion host"
  value       = aws_instance.bastion.public_ip
}
 
output "master_private_ip" {
  description = "Private IP of the master node"
  value       = aws_instance.master.private_ip
}

output "worker_private_ips" {
  description = "Private IPs of the worker nodes"
  value       = [for instance in aws_instance.worker : instance.private_ip]
}

output "nlb_dns" {
  value = aws_lb.k8s_nlb.dns_name
}
