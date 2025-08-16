
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
