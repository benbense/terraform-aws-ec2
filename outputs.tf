output "consul_servers_private_ips" {
  description = "Private IP's of the Consul servers"
  value       = aws_instance.consul_servers.*.private_ip
}

output "jenkins_server_private_ip" {
  description = "Private IP of the Jenkins server"
  value       = aws_instance.jenkins_server.*.private_ip
}

output "jenkins_nodes_private_ip" {
  description = "Private IP's of the Jenkins nodes"
  value       = aws_instance.jenkins_nodes.*.private_ip
}

output "bastion_server_public_ip" {
  description = "Public IP of the Bastion host"
  value       = aws_instance.bastion_server.*.public_ip
}

output "bastion_server_private_ip" {
  description = "Private IP of the Bastion host"
  value       = aws_instance.bastion_server.*.private_ip
}

output "ansible_server_private_ip" {
  description = "Private IP of the Ansible server"
  value       = aws_instance.ansible_server.*.private_ip
}

output "consul_alb_public_dns" {
  description = "Consul ALB Public DNS name"
  value       = aws_alb.consul_alb.dns_name
}

output "jenkins_alb_public_dns" {
  description = "Jenkins ALB Public DNS name"
  value       = aws_alb.jenkins_alb.dns_name
}

output "grafana_alb_public_dns" {
  description = "Grafana ALB Public DNS name"
  value       = aws_alb.grafana_alb.dns_name
}

output "prometheus_alb_public_dns" {
  description = "Prometheus ALB Public DNS name"
  value       = aws_alb.prometheus_alb.dns_name
}

output "jenkins_nodes_arns" {
  description = "ARN of the Jenkins Nodes Instances"
  value       = aws_instance.jenkins_nodes.*.arn
}

output "jenkins_nodes_ids" {
  description = "ID of the Jenkins Nodes Instances"
  value       = aws_instance.jenkins_nodes.*.id
}

output "elk_server_private_ip" {
  description = "Private IP of the ELK server"
  value       = aws_instance.elk_server.*.private_ip
}
