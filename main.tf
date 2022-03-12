###############################################################
# This module creates:
# EC2 Webservers instances
# EC2 Databases instances
# Application Load Balancer
# S3 Bucket reference for ALB
# Security Groups
# User Data for Nginx deployment
###############################################################

########################EC2 Instances##########################
# Grafana Server
resource "aws_instance" "grafana_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnets_ids[0]
  vpc_security_group_ids = [aws_security_group.ssh_sg.id, aws_security_group.consul_agents_sg.id, aws_security_group.grafana_sg.id, aws_security_group.node_exporter_sg.id]
  key_name               = var.server_key
  source_dest_check      = false
  iam_instance_profile   = var.instance_profile_name
  tags                   = zipmap(var.servers_tags_structure, ["grafana", "monitoring", "server", "Grafana-Server", "private", "kandula", "Ben", "true", "ubuntu"])
}

# Prometheus Server
resource "aws_instance" "prometheus_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnets_ids[0]
  vpc_security_group_ids = [aws_security_group.ssh_sg.id, aws_security_group.consul_agents_sg.id, aws_security_group.prometheus_sg.id, aws_security_group.node_exporter_sg.id]
  key_name               = var.server_key
  source_dest_check      = false
  iam_instance_profile   = var.instance_profile_name
  tags                   = zipmap(var.servers_tags_structure, ["prometheus", "monitoring", "server", "Prometheus-Server", "private", "kandula", "Ben", "true", "ubuntu"])
}

# Consul Servers
resource "aws_instance" "consul_servers" {
  count                  = var.consul_servers_count
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = element(var.private_subnets_ids, count.index)
  vpc_security_group_ids = [aws_security_group.consul_servers_sg.id, aws_security_group.ssh_sg.id, aws_security_group.node_exporter_sg.id]
  key_name               = var.server_key
  source_dest_check      = false
  iam_instance_profile   = var.instance_profile_name
  tags                   = zipmap(var.servers_tags_structure, ["consul", "service_discovery", "server", "Consul-Server-${count.index}", "private", "kandula", "Ben", "true", "ubuntu"])

}

resource "aws_instance" "jenkins_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnets_ids[0]
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id, aws_security_group.ssh_sg.id, aws_security_group.consul_agents_sg.id, aws_security_group.node_exporter_sg.id]
  key_name               = var.server_key
  source_dest_check      = false
  iam_instance_profile   = var.instance_profile_name
  tags                   = zipmap(var.servers_tags_structure, ["jenkins", "cicd", "server", "Jenkins-Server", "private", "kandula", "Ben", "true", "ubuntu"])
}

resource "aws_instance" "jenkins_nodes" {
  count                  = var.jenkins_nodes_count
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = element(var.private_subnets_ids, count.index)
  vpc_security_group_ids = [aws_security_group.ssh_sg.id, aws_security_group.consul_agents_sg.id, aws_security_group.node_exporter_sg.id]
  key_name               = var.server_key
  source_dest_check      = false
  iam_instance_profile   = var.instance_profile_name
  tags                   = zipmap(var.servers_tags_structure, ["jenkins", "cicd", "node", "Jenkins-Node-${count.index}", "private", "kandula", "Ben", "true", "ubuntu"])
}

resource "aws_instance" "bastion_server" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  subnet_id                   = var.public_subnets_ids[0]
  vpc_security_group_ids      = [aws_security_group.ssh_sg.id, aws_security_group.consul_agents_sg.id, aws_security_group.node_exporter_sg.id, aws_security_group.bastion_ssh_sg.id]
  key_name                    = var.server_key
  associate_public_ip_address = true
  iam_instance_profile        = var.instance_profile_name
  tags                        = zipmap(var.servers_tags_structure, ["bastion", "bastion", "server", "Bastion-Server", "public", "kandula", "Ben", "true", "ubuntu"])
}

resource "aws_instance" "ansible_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnets_ids[0]
  vpc_security_group_ids = [aws_security_group.ssh_sg.id, aws_security_group.consul_agents_sg.id, aws_security_group.node_exporter_sg.id]
  key_name               = var.server_key
  source_dest_check      = false
  iam_instance_profile   = var.instance_profile_name
  tags                   = zipmap(var.servers_tags_structure, ["ansible", "configuration_management", "server", "Ansible-Server", "private", "kandula", "Ben", "true", "ubuntu"])
}

resource "aws_instance" "elk_server" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t3.medium"
  subnet_id              = var.private_subnets_ids[0]
  vpc_security_group_ids = [aws_security_group.ssh_sg.id, aws_security_group.consul_agents_sg.id, aws_security_group.node_exporter_sg.id, aws_security_group.elk_servers_sg.id]
  key_name               = var.server_key
  source_dest_check      = false
  iam_instance_profile   = var.instance_profile_name
  tags                   = zipmap(var.servers_tags_structure, ["elk", "logging", "server", "ELK-Server", "private", "kandula", "Ben", "true", "ubuntu"])
}

######################## ALB's ###########################

#Consul ALB

resource "aws_alb" "consul_alb" {
  name               = "consul-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.https_sg.id, aws_security_group.http_sg.id]
  subnets            = var.public_subnets_ids
  access_logs {
    bucket  = resource.aws_s3_bucket.s3_logs_bucket.bucket
    prefix  = "logs/consul-alb"
    enabled = true
  }
}

resource "aws_alb_target_group_attachment" "consul_servers_alb_attach" {
  count            = length(aws_instance.consul_servers)
  target_group_arn = aws_alb_target_group.consul_alb_tg.arn
  target_id        = aws_instance.consul_servers.*.id[count.index]
  port             = 8500
}


resource "aws_alb_target_group" "consul_alb_tg" {
  name     = "consul-alb-tg"
  port     = 80
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
    path                = "/v1/status/leader"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 10
  }
}

resource "aws_alb_listener" "consul_https_alb_listener" {
  load_balancer_arn = aws_alb.consul_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.kandula_ssl_cert
  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.consul_alb_tg.arn
  }
}

resource "aws_alb_listener" "consul_http_alb_listener" {
  load_balancer_arn = aws_alb.consul_alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# Jenkins ALB

resource "aws_alb" "jenkins_alb" {
  name               = "jenkins-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.https_sg.id, aws_security_group.http_sg.id]
  subnets            = var.public_subnets_ids
  access_logs {
    bucket  = resource.aws_s3_bucket.s3_logs_bucket.bucket
    prefix  = "logs/jenkins-alb"
    enabled = true
  }
}

resource "aws_alb_target_group_attachment" "jenkins_server_alb_attach" {
  target_group_arn = aws_alb_target_group.jenkins_alb_tg.arn
  target_id        = aws_instance.jenkins_server.id
  port             = 8080
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
    port                = 8080
    protocol            = "HTTP"
    path                = "/login"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 10
  }
}

resource "aws_alb_listener" "jenkins_https_alb_listener" {
  load_balancer_arn = aws_alb.jenkins_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.kandula_ssl_cert
  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.jenkins_alb_tg.arn
  }
}

resource "aws_alb_listener" "jenkins_http_alb_listener" {
  load_balancer_arn = aws_alb.jenkins_alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}
# Grafana ALB

resource "aws_alb" "grafana_alb" {
  name               = "grafana-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.https_sg.id, aws_security_group.http_sg.id]
  subnets            = var.public_subnets_ids
  access_logs {
    bucket  = resource.aws_s3_bucket.s3_logs_bucket.bucket
    prefix  = "logs/grafana-alb"
    enabled = true
  }
}

resource "aws_alb_target_group_attachment" "grafana_server_alb_attach" {
  target_group_arn = aws_alb_target_group.grafana_alb_tg.arn
  target_id        = aws_instance.grafana_server.id
  port             = 3000
}


resource "aws_alb_target_group" "grafana_alb_tg" {
  name     = "grafana-alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  stickiness {
    type            = "lb_cookie"
    cookie_duration = 60
    enabled         = true
  }
  health_check {
    port                = 3000
    protocol            = "HTTP"
    path                = "/api/health"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 10
  }
}

resource "aws_alb_listener" "grafana_https_alb_listener" {
  load_balancer_arn = aws_alb.grafana_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.kandula_ssl_cert
  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.grafana_alb_tg.arn
  }
}

resource "aws_alb_listener" "grafana_http_alb_listener" {
  load_balancer_arn = aws_alb.grafana_alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# Prometheus ALB

resource "aws_alb" "prometheus_alb" {
  name               = "prometheus-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.https_sg.id, aws_security_group.http_sg.id]
  subnets            = var.public_subnets_ids
  access_logs {
    bucket  = resource.aws_s3_bucket.s3_logs_bucket.bucket
    prefix  = "logs/prometheus-alb"
    enabled = true
  }
}

resource "aws_alb_target_group_attachment" "prometheus_server_alb_attach" {
  target_group_arn = aws_alb_target_group.prometheus_alb_tg.arn
  target_id        = aws_instance.prometheus_server.id
  port             = 9090
}


resource "aws_alb_target_group" "prometheus_alb_tg" {
  name     = "prometheus-alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  stickiness {
    type            = "lb_cookie"
    cookie_duration = 60
    enabled         = true
  }
  health_check {
    port                = 9090
    protocol            = "HTTP"
    path                = "/status"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 10
  }
}

resource "aws_alb_listener" "prometheus_https_alb_listener" {
  load_balancer_arn = aws_alb.prometheus_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.kandula_ssl_cert
  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.prometheus_alb_tg.arn
  }
}

resource "aws_alb_listener" "prometheus_http_alb_listener" {
  load_balancer_arn = aws_alb.prometheus_alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# ELK ALB

resource "aws_alb" "elk_alb" {
  name               = "elk-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.https_sg.id, aws_security_group.http_sg.id]
  subnets            = var.public_subnets_ids
  access_logs {
    bucket  = resource.aws_s3_bucket.s3_logs_bucket.bucket
    prefix  = "logs/elk-alb"
    enabled = true
  }
}

resource "aws_alb_target_group_attachment" "elk_server_alb_attach" {
  target_group_arn = aws_alb_target_group.elk_alb_tg.arn
  target_id        = aws_instance.elk_server.id
  port             = 5601
}


resource "aws_alb_target_group" "elk_alb_tg" {
  name     = "elk-alb-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  stickiness {
    type            = "lb_cookie"
    cookie_duration = 60
    enabled         = true
  }
  health_check {
    port                = 5601
    protocol            = "HTTP"
    path                = "/status"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 10
  }
}

resource "aws_alb_listener" "elk_https_alb_listener" {
  load_balancer_arn = aws_alb.elk_alb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.kandula_ssl_cert
  default_action {
    type             = "forward"
    target_group_arn = aws_alb_target_group.elk_alb_tg.arn
  }
}

resource "aws_alb_listener" "elk_http_alb_listener" {
  load_balancer_arn = aws_alb.elk_alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type = "redirect"
    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}


# Security Groups

# Grafana Security Group
resource "aws_security_group" "grafana_sg" {
  name        = "grafana_sg"
  description = "Security group for Grafana"
  vpc_id      = var.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  dynamic "ingress" {
    iterator = port
    for_each = var.grafana_ingress_ports
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = [var.cidr_block]
    }
  }
}


# Node Exporter Security Group
resource "aws_security_group" "node_exporter_sg" {
  name        = "node_exporter_sg"
  description = "Security group for Node Exporter"
  vpc_id      = var.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  dynamic "ingress" {
    iterator = port
    for_each = var.node_exporter_ingress_ports
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = [var.cidr_block]
    }
  }
}

# Prometheus Security Group
resource "aws_security_group" "prometheus_sg" {
  name        = "prometheus_sg"
  description = "Security group for Prometheus DB and Web Access"
  vpc_id      = var.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  dynamic "ingress" {
    iterator = port
    for_each = var.prometheus_ingress_ports
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = [var.cidr_block]
    }
  }
}

#Consul Security Group
resource "aws_security_group" "https_sg" {
  name        = "https_sg"
  description = "Security group for HTTPS Access"
  vpc_id      = var.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  dynamic "ingress" {
    iterator = port
    for_each = var.https_ingress_ports
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}

resource "aws_security_group" "http_sg" {
  name        = "http_sg"
  description = "Security group for HTTP Access"
  vpc_id      = var.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  dynamic "ingress" {
    iterator = port
    for_each = var.http_ingress_ports
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}

resource "aws_security_group" "consul_servers_sg" {
  name        = "consul_servers_sg"
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
    for_each = var.consul_server_ingress_ports
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = [var.cidr_block]
    }
  }

  dynamic "ingress" {
    iterator = port
    for_each = var.consul_server_ingress_ports
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "udp"
      cidr_blocks = [var.cidr_block]
    }
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = [var.cidr_block]
  }
}

resource "aws_security_group" "consul_agents_sg" {
  name        = "consul_agents_sg"
  description = "Security group for Consul agents"
  vpc_id      = var.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  dynamic "ingress" {
    iterator = port
    for_each = var.consul_agent_ingress_ports
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = [var.cidr_block]
    }
  }
  dynamic "ingress" {
    iterator = port
    for_each = var.consul_server_ingress_ports
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "udp"
      cidr_blocks = [var.cidr_block]
    }
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = [var.cidr_block]
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
      cidr_blocks = [var.cidr_block]
    }
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = [var.cidr_block]
  }
}


resource "aws_security_group" "ssh_sg" {
  name        = "ssh_sg"
  description = "Security group for SSH"
  vpc_id      = var.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  dynamic "ingress" {
    iterator = port
    for_each = var.ssh_ingress_ports
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = [var.cidr_block]
    }
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = [var.cidr_block]
  }
}


# Enable TCP access to port 80
resource "aws_security_group" "inbound_http_any" {
  vpc_id = var.vpc_id
  ingress {
    cidr_blocks = [var.cidr_block]
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
  }
  tags = {
    "Name" = "inbound_http_any"
  }
}

resource "aws_security_group" "elk_servers_sg" {
  name        = "elk_servers_sg"
  description = "Security group for ELK servers"
  vpc_id      = var.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  dynamic "ingress" {
    iterator = port
    for_each = var.elk_ingress_ports
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = [var.cidr_block]
    }
  }

  ingress {
    from_port   = 8
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = [var.cidr_block]
  }
}

resource "aws_security_group" "bastion_ssh_sg" {
  name        = "bastion_ssh_ingress"
  description = "Security group for Bastion SSH"
  vpc_id      = var.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  dynamic "ingress" {
    iterator = port
    for_each = var.ssh_ingress_ports
    content {
      from_port   = port.value
      to_port     = port.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}
########################### S3 ##########################

resource "aws_s3_bucket" "s3_logs_bucket" {
  bucket        = var.bucket_name
  force_destroy = true # only for testing
  acl           = "log-delivery-write"
}

resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.s3_logs_bucket.id
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${var.elb_account_id}:root"
        },
        "Action" : "s3:PutObject",
        "Resource" : "arn:aws:s3:::${var.bucket_name}/*"
      },
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "delivery.logs.amazonaws.com"
        },
        "Action" : "s3:PutObject",
        "Resource" : "arn:aws:s3:::${var.bucket_name}/*",
        "Condition" : {
          "StringEquals" : {
            "s3:x-amz-acl" : "bucket-owner-full-control"
          }
        }
      },
      {
        "Effect" : "Allow",
        "Principal" : {
          "Service" : "delivery.logs.amazonaws.com"
        },
        "Action" : "s3:GetBucketAcl",
        "Resource" : "arn:aws:s3:::${var.bucket_name}"
      }
    ]
  })
}

resource "aws_route53_record" "elk_server" {
  zone_id = var.route53_zone_id
  name    = "elk.kandula"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.elk_server.private_ip}"]
}

resource "aws_route53_record" "grafana_server" {
  zone_id = var.route53_zone_id
  name    = "grafana.kandula"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.grafana_server.private_ip}"]
}
resource "aws_route53_record" "prometheus_server" {
  zone_id = var.route53_zone_id
  name    = "prometheus.kandula"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.prometheus_server.private_ip}"]
}
resource "aws_route53_record" "consul_servers" {
  count   = length(aws_instance.consul_servers)
  zone_id = var.route53_zone_id
  name    = "consul${count.index}.kandula"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.consul_servers[count.index].private_ip}"]
}
resource "aws_route53_record" "jenkins_server" {
  zone_id = var.route53_zone_id
  name    = "jenkins.kandula"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.jenkins_server.private_ip}"]
}
resource "aws_route53_record" "jenkins_nodes" {
  count   = length(aws_instance.jenkins_nodes)
  zone_id = var.route53_zone_id
  name    = "jenkins${count.index}.kandula"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.jenkins_nodes[count.index].private_ip}"]
}
resource "aws_route53_record" "bastion_server" {
  zone_id = var.route53_zone_id
  name    = "bastion.kandula"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.bastion_server.private_ip}"]
}
resource "aws_route53_record" "ansible_server" {
  zone_id = var.route53_zone_id
  name    = "ansible.kandula"
  type    = "A"
  ttl     = "300"
  records = ["${aws_instance.ansible_server.private_ip}"]
}
