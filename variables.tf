variable "private_key_path" {
  description = "Private key path"
  default     = "C:\\Keys\\Homework1.pem"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64*"]
  }
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "instance_type" {
  description = "EC2 Instance type"
  type        = string
}

variable "private_subnets_ids" {
  description = "List of private subnets ids"
  type        = list(string)
}

variable "public_subnets_ids" {
  description = "List of public subnets ids"
  type        = list(string)
}

variable "available_zone_names" {
  description = "List of avilabale AZ's"
  type        = list(string)
}

variable "bucket_name" {
  description = "S3 Bucket name for logs"
  type        = string
}

variable "consul_servers_count" {
  description = "How much Consul servers to create"
  type        = number
  validation {
    condition     = var.consul_servers_count == 1 || var.consul_servers_count == 3 || var.consul_servers_count == 5
    error_message = "Invalid Consul servers amount."
  }
}

variable "consul_ingress_ports" {
  type        = list(number)
  description = "Consul ingress ports list"
  default     = [8600, 8500, 8300, 8301, 8302]
}

variable "jenkins_ingress_ports" {
  type        = list(number)
  description = "Jenkins ingress ports list"
  default     = [49187, 80, 8080, 22]
}

variable "bastion_ingress_ports" {
  type        = list(number)
  description = "Bastion host ingress ports list"
  default     = [22]
}

variable "ansible_ingress_ports" {
  type        = list(number)
  description = "Ansible host ingress ports list"
  default     = [80, 8080, 22]
}
