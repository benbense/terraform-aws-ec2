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
}

variable "jenkins_nodes_count" {
  description = "How much Jenkins nodes to create"
  type        = number
}


variable "consul_server_ingress_ports" {
  type        = list(number)
  description = "Consul ingress ports list"
  default     = [8600, 8500, 8300, 8301]
}

variable "consul_agent_ingress_ports" {
  type        = list(number)
  description = "Consul agent ingress ports list"
  default     = [8301, 8600]
}

variable "jenkins_ingress_ports" {
  type        = list(number)
  description = "Jenkins ingress ports list"
  default     = [80, 8080]
}

variable "ssh_ingress_ports" {
  type        = list(number)
  description = "SSH ingress ports list"
  default     = [22]
}

variable "https_ingress_ports" {
  type        = list(number)
  description = "HTTPS ingress ports"
  default     = [443]
}

variable "ssl_security_policy" {
  type        = string
  description = "SSL Security Policy"
  default     = "ELBSecurityPolicy-2016-08"
}

variable "servers_tags_structure" {
  type        = list(string)
  description = "Consul server tags map"
  default     = ["service", "service_role", "instance_type", "Name", "subnet_type", "project", "owner", "is_consul_monitored", "os_type"]
}

variable "instance_profile_name" {
  type        = string
  description = "IAM role name for instance"
}

variable "server_key" {
  type        = string
  description = "Public SSH key name"
}

variable "elb_account_id" {
  description = "ELB Account ID - pick one according to region https://docs.aws.amazon.com/elasticloadbalancing/latest/application/load-balancer-access-logs.html#access-logging-bucket-permissions"
  type        = string
}

variable "kandula_ssl_cert" {
  description = "ARN of SSL Certificate"
  type        = string
}
variable "ssl_policy" {
  description = "SSL Security Policy"
  type        = string
}
