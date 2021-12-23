###############################################################
# This module creates:
# EC2 Webservers instances
# EC2 Databases instances
# Application Load Balancer
# S3 Bucket reference for ALB
# Security Groups
# User Data for Nginx deployment
###############################################################

########################Create Keys##########################
resource "tls_private_key" "server_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "server_key" {
  key_name   = "server_key"
  public_key = tls_private_key.server_key.public_key_openssh
}

resource "local_file" "server_key" {
  sensitive_content = tls_private_key.server_key.private_key_pem
  filename          = var.private_key_path
}


########################EC2 Instances##########################

# Consul Servers
resource "aws_instance" "consul_servers" {
  count                  = var.consul_servers_count
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = element(var.private_subnets_ids, count.index)
  vpc_security_group_ids = [aws_security_group.consul_sg.id]
  key_name               = aws_key_pair.server_key.key_name
  tags                   = zipmap(var.servers_tags_structure, ["consul", "service_discovery", "server", "Consul-Server-${count.index}", "private", "kandula", "Ben"])

}

resource "aws_instance" "jenkins_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnets_ids[0]
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  key_name               = aws_key_pair.server_key.key_name
  tags                   = zipmap(var.servers_tags_structure, ["jenkins", "cicd", "server", "Jenkins-Server", "private", "kandula", "Ben"])
}

resource "aws_instance" "jenkins_nodes" {
  count                  = var.jenkins_nodes_count
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = element(var.private_subnets_ids, count.index)
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  key_name               = aws_key_pair.server_key.key_name
  tags                   = zipmap(var.servers_tags_structure, ["jenkins", "service_discovery", "node", "Jenkins-Node-${count.index}", "private", "kandula", "Ben"])
}

resource "aws_instance" "bastion_server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = var.private_subnets_ids[0]
  vpc_security_group_ids      = [aws_security_group.bastion_sg.id]
  key_name                    = aws_key_pair.server_key.key_name
  associate_public_ip_address = true
  tags                        = zipmap(var.servers_tags_structure, ["bastion", "bastion", "server", "Bastion-Server", "public", "kandula", "Ben"])
}

resource "aws_instance" "ansible_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnets_ids[0]
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  key_name               = aws_key_pair.server_key.key_name
  tags                   = zipmap(var.servers_tags_structure, ["ansible", "configuration_management", "server", "Ansible-Server", "private", "kandula", "Ben"])
}

######################## ALB's ###########################

#Consul ALB

resource "aws_alb" "consul_alb" {
  name               = "consul-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.consul_sg.id]
  subnets            = var.public_subnets_ids
  access_logs {
    bucket  = data.aws_s3_bucket.main_bucket.bucket
    prefix  = "logs/consul-alb"
    enabled = true
  }
}

resource "aws_alb_target_group_attachment" "consul_servers_alb_attach" {
  count            = length(aws_instance.consul_servers)
  target_group_arn = aws_alb_target_group.consul_alb_tg.arn
  target_id        = aws_instance.consul_servers.*.id[count.index]
  port             = 80
}


resource "aws_alb_target_group" "consul_alb_tg" {
  name     = "consul-alb-tg"
  port     = 8500
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  stickiness {
    type            = "lb_cookie"
    cookie_duration = 60
    enabled         = true
  }
  health_check {
    port                = 8500
    protocol            = "HTTP"
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 10
  }
}

resource "aws_alb_listener" "consul_alb_listener" {
  load_balancer_arn = aws_alb.consul_alb.arn
  port              = "8500"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.consul_alb_tg.arn
  }
}

# Jenkins ALB

resource "aws_alb" "jenkins_alb" {
  name               = "jenkins-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.jenkins_sg.id]
  subnets            = var.public_subnets_ids
  access_logs {
    bucket  = data.aws_s3_bucket.main_bucket.bucket
    prefix  = "logs/jenkins-alb"
    enabled = true
  }
}

resource "aws_alb_target_group_attachment" "jenkins_server_alb_attach" {
  target_group_arn = aws_alb_target_group.jenkins_alb_tg.arn
  target_id        = aws_instance.jenkins_server.id
  port             = 80
}


resource "aws_alb_target_group" "jenkins_alb_tg" {
  name     = "jenkins-alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  stickiness {
    type            = "lb_cookie"
    cookie_duration = 60
    enabled         = true
  }
  health_check {
    port                = 80
    protocol            = "HTTP"
    path                = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 10
  }
}

resource "aws_alb_listener" "jenkins_alb_listener" {
  load_balancer_arn = aws_alb.jenkins_alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.jenkins_alb_tg.arn
  }
}

# S3 Bucket Data
data "aws_s3_bucket" "main_bucket" {
  bucket = var.bucket_name
}

# Security Groups

#Consul Security Group

resource "aws_security_group" "consul_sg" {
  name        = "consul_sg"
  description = "Security group for Consul servers"
  vpc_id      = var.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  dynamic "ingress" {
    iterator = port
    for_each = var.consul_ingress_ports
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins_sg"
  description = "Security group for Jenkins server"
  vpc_id      = var.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  dynamic "ingress" {
    iterator = port
    for_each = var.jenkins_ingress_ports
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "bastion_sg" {
  name        = "bastion_sg"
  description = "Security group for Bastion server"
  vpc_id      = var.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  dynamic "ingress" {
    iterator = port
    for_each = var.bastion_ingress_ports
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ansible_sg" {
  name        = "ansible_sg"
  description = "Security group for Ansible server"
  vpc_id      = var.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  dynamic "ingress" {
    iterator = port
    for_each = var.ansible_ingress_ports
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


# Enable TCP access to port 80
resource "aws_security_group" "inbound_http_any" {
  vpc_id = var.vpc_id
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
  }
  tags = {
    "Name" = "inbound_http_any"
  }
}

# Enable SSH access to port 22
resource "aws_security_group" "inbound_ssh_any" {
  vpc_id = var.vpc_id
  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }
  tags = {
    "Name" = "inbound_ssh_any"
  }
}

# Enable instance access to the world
resource "aws_security_group" "outbound_any" {
  vpc_id = var.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    "Name" = "outbound_any"
  }
}

# User Data
locals {
  webservers-instance-userdata = <<USERDATA
#!/bin/bash
sudo apt update -y
sudo apt install nginx -y
sed -i "s/nginx/Grandpa's Whiskey $HOSTNAME/g" /var/www/html/index.nginx-debian.html
sed -i '15,23d' /var/www/html/index.nginx-debian.html
service nginx restart
USERDATA
}

