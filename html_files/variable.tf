variable "aws_region" { default = "ap-south-1" }
variable "vpc_cidr" { default = "10.0.0.0/16" }

variable "public_subnet_a" { default = "10.0.1.0/24" }
variable "public_subnet_b" { default = "10.0.2.0/24" }
variable "private_subnet_a" { default = "10.0.101.0/24" }
variable "private_subnet_b" { default = "10.0.102.0/24" }

variable "az1" { default = "ap-south-1a" }
variable "az2" { default = "ap-south-1b" }

variable "my_ip" {}
variable "key_name" {}
variable "ssh_pub_key_path" {}
variable "ubuntu_ami" { default = "ami-0d5d9d301c853a04a" } # Ubuntu 22.04 LTS
variable "bastion_type" { default = "t2.micro" }
variable "asg_instance_type" { default = "t2.micro" }
