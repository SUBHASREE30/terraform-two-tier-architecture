# Infrastructure as Code (IaC) with Terraform
## Two-Tier Web Application Architecture

**Author:** Subhasree M  
**Project:** Cloud Computing Internship - Project 2  
**Tool:** Terraform (HashiCorp)  
**Cloud:** AWS (Asia Pacific - Mumbai)

---

## Project Overview

This project automates the deployment of a Two-Tier Web Application Architecture using **Terraform** — eliminating manual "ClickOps" with Infrastructure as Code (IaC).

With a single command `terraform apply`, the entire infrastructure is provisioned automatically.

---

## Architecture Diagram

```
                        INTERNET
                            |
                    [Internet Gateway]
                            |
                    ┌───────────────┐
                    │   VPC         │
                    │ 10.0.0.0/16   │
                    │               │
                    │ ┌───────────┐ │
                    │ │Public     │ │
                    │ │Subnet     │ │
                    │ │10.0.1.0/24│ │
                    │ │           │ │
                    │ │[Web Server]│ │
                    │ │ Apache +  │ │
                    │ │   PHP     │ │
                    │ └─────┬─────┘ │
                    │       │Port   │
                    │       │3306   │
                    │ ┌─────▼─────┐ │
                    │ │Private    │ │
                    │ │Subnet     │ │
                    │ │10.0.2.0/24│ │
                    │ │           │ │
                    │ │[DB Server]│ │
                    │ │  MySQL    │ │
                    │ └───────────┘ │
                    └───────────────┘
```

---

## Files Structure

```
terraform-project/
├── main.tf          # Core infrastructure (VPC, Subnets, EC2, Security Groups)
├── variables.tf     # Input variables (region, CIDR, instance type)
├── outputs.tf       # Output values (IPs, DNS, SSH commands)
├── .gitignore       # Ignores sensitive files (tfstate, keys)
└── README.md        # This file
```

---

## Prerequisites

- [Terraform CLI](https://developer.hashicorp.com/terraform/downloads) installed
- [AWS CLI](https://aws.amazon.com/cli/) installed and configured
- AWS Account with appropriate permissions

---

## How to Deploy

### Step 1: Configure AWS Credentials
```bash
aws configure
# Enter: AWS Access Key ID
# Enter: AWS Secret Access Key
# Enter: Default region (ap-south-1)
# Enter: Default output format (json)
```

### Step 2: Initialize Terraform
```bash
terraform init
```
Downloads the AWS provider plugin.

### Step 3: Plan the Infrastructure
```bash
terraform plan
```
Shows what Terraform will create (review before applying).

**Expected output:**
```
Plan: 10 to add, 0 to change, 0 to destroy.
```

### Step 4: Apply (Create Infrastructure)
```bash
terraform apply
```
Type `yes` when prompted. Terraform creates all resources.

### Step 5: Verify
After apply, Terraform outputs:
- **Web Server Public IP** — open in browser
- **Database Connection Test URL** — shows "Database Connection: OK"

### Step 6: Destroy (Clean up to avoid charges)
```bash
terraform destroy
```
Tears down ALL resources. Always destroy after testing!

---

## Security Architecture

| Resource | Rule | Source |
|----------|------|--------|
| Web SG | Port 80 (HTTP) | 0.0.0.0/0 (Internet) |
| Web SG | Port 443 (HTTPS) | 0.0.0.0/0 (Internet) |
| Web SG | Port 22 (SSH) | Your IP |
| DB SG | Port 3306 (MySQL) | Web SG ID only |
| DB SG | Port 22 (SSH) | Web SG ID only |

> **Key Security Concept:** The Database Security Group references the **Web Security Group ID** — not an IP address. This means ONLY machines in the Web Server group can reach the database.

---

## Resources Created by Terraform

1. `aws_vpc` — Custom VPC (10.0.0.0/16)
2. `aws_subnet` — Public Subnet (10.0.1.0/24)
3. `aws_subnet` — Private Subnet (10.0.2.0/24)
4. `aws_internet_gateway` — Internet Gateway
5. `aws_route_table` — Public Route Table
6. `aws_route_table_association` — Links Public Subnet to Route Table
7. `aws_security_group` — Web Server Security Group
8. `aws_security_group` — Database Security Group
9. `aws_instance` — Web Server (Public Subnet)
10. `aws_instance` — Database Server (Private Subnet)

---

## Key Terraform Concepts Demonstrated

- **Provider Block** — Connects Terraform to AWS
- **Resource Blocks** — Defines each infrastructure component
- **Variables** — Reusable values (no hardcoding)
- **Outputs** — Prints useful info after deployment
- **Dependencies** — DB Security Group references Web SG ID
- **Tags** — All resources tagged with `ManagedBy = Terraform`
- **State File** — `terraform.tfstate` tracks what was built
- **Lifecycle** — init → plan → apply → destroy
