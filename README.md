
# CloudOps Dashboard Terraform Project

## Overview
This project deploys a **production-ready AWS environment** using Terraform:

- **VPC** with public and private subnets in **two Availability Zones**  
- **NAT Gateways** for private subnet internet access  
- **Bastion host** for secure SSH access  
- **Application Load Balancer (ALB)** forwarding traffic to Auto Scaling Group (ASG)  
- **Auto Scaling Group** hosting Ubuntu servers running a Python HTTP server  
- **HTML Dashboard** served from port 8000 on instances  

This setup ensures **high availability, resiliency, and security** for a simple web application.

---

## Architecture Diagram

```text
                Internet
                   |
                 ALB (Port 80)
                 /         \
       Private Subnet A   Private Subnet B
       ----------------   ----------------
       | Python HTTP |   | Python HTTP |
       ----------------   ----------------
             |                 |
            ASG (2 instances in total)
             |
        NAT Gateways (for outbound internet)
             |
         Bastion Host (public subnet)

## Folder Structure

cloudops-dashboard-terraform/
├── main.tf # Core AWS resources: VPC, subnets, NAT, ALB, ASG, Bastion
├── variables.tf # Input variables for flexibility (CIDR, SSH key, IP, etc.)
├── terraform.tfvars # User-specific values (public IP, SSH key path)
├── outputs.tf # Outputs like ALB DNS, Bastion IP, ASG instance IDs
├── html_files/
│ └── index.html # Dashboard HTML page served by instances
├── README.md # Project overview and instructions


---

## Prerequisites

Before deploying, ensure you have:

- Terraform >= 1.5.0 installed  
- AWS CLI configured with proper IAM permissions  
- SSH key pair (private key available locally)  

---

## Setup Instructions

Follow these steps to deploy the project:

1. Clone the repository
git clone https://github.com/<your-username>/cloudops-dashboard-terraform.git
cd cloudops-dashboard-terraform

2. Update your variables
Edit terraform.tfvars with your information:

my_ip           = "YOUR_PUBLIC_IP/32"
key_name        = "my-aws-key"
ssh_pub_key_path = "~/.ssh/id_rsa.pub"


3. Initialize Terraform

terraform init


4. Check the deployment plan

terraform plan


5. Apply the configuration

terraform apply


6. Check outputs

terraform output

---


###  Accessing the Application   ###

HTML Dashboard: Open the ALB DNS in a web browser.

Bastion Host: SSH into the bastion server to access private instances.

ssh -i <path-to-your-private-key> ubuntu@<bastion-public-ip>


Dashboard port: Instances serve HTML via Python HTTP server on port 8000.

----

###   Notes   ###

* Ensure ALB health check path is / so that instances appear healthy.

*  Bastion host is required to SSH into private instances.

*  Auto Scaling ensures resiliency across two Availability Zones.

###   Future Enhancements  ###

1. Add HTTPS support using ACM certificates for ALB

2. Serve dashboard via Nginx instead of Python HTTP server

3. Add CI/CD pipeline using GitHub Actions for automated Terraform deployment
