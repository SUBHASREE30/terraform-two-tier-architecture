# outputs.tf - Output Values after Terraform Apply
# Author: Subhasree M

output "vpc_id" {
  description = "ID of the created VPC"
  value       = aws_vpc.main_vpc.id
}

output "public_subnet_id" {
  description = "ID of the Public Subnet (Web Tier)"
  value       = aws_subnet.public_subnet.id
}

output "private_subnet_id" {
  description = "ID of the Private Subnet (Database Tier)"
  value       = aws_subnet.private_subnet.id
}

output "web_server_public_ip" {
  description = "Public IP of the Web Server - Open this in browser!"
  value       = aws_instance.web_server.public_ip
}

output "web_server_public_dns" {
  description = "Public DNS of the Web Server"
  value       = aws_instance.web_server.public_dns
}

output "db_server_private_ip" {
  description = "Private IP of the Database Server (not publicly accessible)"
  value       = aws_instance.db_server.private_ip
}

output "web_security_group_id" {
  description = "ID of the Web Server Security Group"
  value       = aws_security_group.web_sg.id
}

output "db_security_group_id" {
  description = "ID of the Database Security Group"
  value       = aws_security_group.db_sg.id
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = aws_internet_gateway.igw.id
}

output "ssh_command_web_server" {
  description = "SSH command to connect to Web Server"
  value       = "ssh -i two-tier-key.pem ubuntu@${aws_instance.web_server.public_ip}"
}

output "ssh_command_db_server" {
  description = "SSH command to connect to DB Server (via Web Server bastion)"
  value       = "ssh -i two-tier-key.pem ubuntu@${aws_instance.db_server.private_ip}"
}

output "database_connection_test_url" {
  description = "URL to test Database Connection from browser"
  value       = "http://${aws_instance.web_server.public_ip}/index.php"
}
