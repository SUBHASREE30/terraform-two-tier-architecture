# main.tf - Two-Tier Web Application Architecture with Terraform
# Author: Subhasree M

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

# Provider Configuration
provider "aws" {
  region = var.aws_region
}

# ============================================================
# PHASE 1: VPC AND NETWORK LAYER
# ============================================================

# Create Custom VPC
resource "aws_vpc" "main_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "two-tier-vpc"
    Project     = "Two-Tier Architecture"
    Environment = "Production"
    ManagedBy   = "Terraform"
  }
}

# Create Public Subnet (Web Tier)
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name    = "public-subnet-web-tier"
    Tier    = "Public"
    ManagedBy = "Terraform"
  }
}

# Create Private Subnet (Database Tier)
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = "${var.aws_region}b"

  tags = {
    Name    = "private-subnet-db-tier"
    Tier    = "Private"
    ManagedBy = "Terraform"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name      = "main-internet-gateway"
    ManagedBy = "Terraform"
  }
}

# Create Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name      = "public-route-table"
    ManagedBy = "Terraform"
  }
}

# Associate Public Route Table with Public Subnet
resource "aws_route_table_association" "public_rta" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# ============================================================
# PHASE 2: SECURITY GROUPS (FIREWALL RULES)
# ============================================================

# Web Server Security Group
resource "aws_security_group" "web_sg" {
  name        = "web-server-sg"
  description = "Security group for Web Server - allows HTTP and SSH"
  vpc_id      = aws_vpc.main_vpc.id

  # Allow HTTP from anywhere (Internet)
  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow HTTPS from anywhere (Internet)
  ingress {
    description = "HTTPS from Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow SSH from anywhere (restrict to your IP in production)
  ingress {
    description = "SSH Access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "web-server-security-group"
    ManagedBy = "Terraform"
  }
}

# Database Server Security Group
resource "aws_security_group" "db_sg" {
  name        = "database-server-sg"
  description = "Security group for Database Server - allows MySQL ONLY from Web SG"
  vpc_id      = aws_vpc.main_vpc.id

  # Allow MySQL ONLY from Web Server Security Group (NOT from internet)
  ingress {
    description     = "MySQL from Web Server only"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  # Allow SSH only from Web Server (Bastion Host)
  ingress {
    description     = "SSH from Web Server (Bastion)"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.web_sg.id]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "database-security-group"
    ManagedBy = "Terraform"
  }
}

# ============================================================
# PHASE 3: EC2 INSTANCES (COMPUTE LAYER)
# ============================================================

# Key Pair for SSH Access
resource "aws_key_pair" "deployer_key" {
  key_name   = "two-tier-key"
  public_key = var.public_key

  tags = {
    Name      = "two-tier-deployer-key"
    ManagedBy = "Terraform"
  }
}

# Web Server Instance (Public Subnet)
resource "aws_instance" "web_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]
  key_name               = aws_key_pair.deployer_key.key_name

  # Install Apache Web Server on startup
  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y apache2 php php-mysql
    systemctl start apache2
    systemctl enable apache2

    # Create a PHP page to test DB connection
    cat > /var/www/html/index.php << 'PHPEOF'
    <?php
    $host = "${aws_instance.db_server.private_ip}";
    $user = "admin";
    $pass = "password123";
    $db   = "testdb";

    $conn = new mysqli($host, $user, $pass, $db);

    if ($conn->connect_error) {
        echo "<h1 style='color:red;'>Database Connection: FAILED</h1>";
        echo "<p>" . $conn->connect_error . "</p>";
    } else {
        echo "<h1 style='color:green;'>Database Connection: OK</h1>";
        echo "<p>Successfully connected to MySQL at " . $host . "</p>";
    }
    ?>
    PHPEOF

    systemctl restart apache2
  EOF

  tags = {
    Name        = "web-server-public"
    Tier        = "Web"
    ManagedBy   = "Terraform"
  }
}

# Database Server Instance (Private Subnet)
resource "aws_instance" "db_server" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private_subnet.id
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  key_name               = aws_key_pair.deployer_key.key_name

  # Install MySQL on startup
  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y mysql-server
    systemctl start mysql
    systemctl enable mysql

    # Configure MySQL to accept remote connections from web server
    sed -i 's/bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
    systemctl restart mysql

    # Create database and user
    mysql -e "CREATE DATABASE testdb;"
    mysql -e "CREATE USER 'admin'@'%' IDENTIFIED BY 'password123';"
    mysql -e "GRANT ALL PRIVILEGES ON testdb.* TO 'admin'@'%';"
    mysql -e "FLUSH PRIVILEGES;"
  EOF

  tags = {
    Name        = "database-server-private"
    Tier        = "Database"
    ManagedBy   = "Terraform"
  }
}
