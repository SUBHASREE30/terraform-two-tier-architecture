# variables.tf - Input Variables for Two-Tier Architecture
# Author: Subhasree M

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-south-1" # Mumbai region
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the Public Subnet (Web Tier)"
  type        = string
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the Private Subnet (Database Tier)"
  type        = string
  default     = "10.0.2.0/24"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t2.micro" # Free tier eligible
}

variable "ami_id" {
  description = "AMI ID for Ubuntu 22.04 LTS in ap-south-1 (Mumbai)"
  type        = string
  default     = "ami-0f58b397bc5c1f2e8" # Ubuntu 22.04 LTS - Mumbai
}

variable "public_key" {
  description = "SSH public key for EC2 key pair"
  type        = string
  default     = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQC... your-key-here"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "project_name" {
  description = "Project name for tagging"
  type        = string
  default     = "two-tier-architecture"
}
