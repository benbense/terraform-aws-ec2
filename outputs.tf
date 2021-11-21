output "db_servers_private_ips" {
  description = "Private IP's of the EC2 Databases"
  value       = aws_instance.databases.*.private_ip
}

output "web_servers_public_ips" {
  description = "Public IP's of the EC2 Webservers"
  value       = aws_instance.webservers.*.public_ip
}

output "web_servers_private_ips" {
  description = "Private IP's of the EC2 Webservers"
  value       = aws_instance.webservers.*.private_ip
}

output "alb_public_dns" {
  description = "ALB Public DNS name"
  value       = aws_alb.webservers.dns_name
}
