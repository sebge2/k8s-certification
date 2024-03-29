provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "main-vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = var.tags
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.main-vpc.id
  tags   = var.tags
}

resource "aws_eip" "eip" {
  vpc        = true
  depends_on = [aws_internet_gateway.gateway]
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.eip.id
  subnet_id     = element(aws_subnet.public_subnet.*.id, 0)
  depends_on    = [aws_internet_gateway.gateway]
  tags          = var.tags
}

resource "aws_subnet" "public_subnet" {
  cidr_block        = "10.0.101.0/24"
  vpc_id            = aws_vpc.main-vpc.id
  availability_zone = "${var.aws_region}${var.aws_main_availability_zone}"
  tags              = var.tags
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main-vpc.id
  tags   = var.tags
}

resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.gateway.id
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public.id
}

resource "aws_vpc_dhcp_options" "local-domain" {
  domain_name          = var.local_domain
  domain_name_servers  = ["AmazonProvidedDNS"]

  tags = var.tags
}

resource "aws_vpc_dhcp_options_association" "local_dns_resolver" {
  vpc_id          = aws_vpc.main-vpc.id
  dhcp_options_id = aws_vpc_dhcp_options.local-domain.id
}

resource "aws_security_group" "ssh" {
  vpc_id      = aws_vpc.main-vpc.id
  name        = "${var.default_resource_name}-ssh"
  description = "Security group that allows SSH connections"

  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 22
    to_port   = 22
    protocol  = "tcp"
  }

  tags = var.tags
}

resource "aws_security_group" "cp" {
  vpc_id      = aws_vpc.main-vpc.id
  name        = "${var.default_resource_name}-cp"
  description = "Security group that allows Control plane connections"

  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 6443
    to_port   = 6443
    protocol  = "tcp"
    description = "Kubernetes API server"
  }

  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 2379
    to_port   = 2380
    protocol  = "tcp"
    description = "etcd server client API"
  }

  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 10259
    to_port   = 10259
    protocol  = "tcp"
    description = "kube-scheduler"
  }

  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 10257
    to_port   = 10257
    protocol  = "tcp"
    description = "kube-controller manager"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_security_group" "worker" {
  vpc_id      = aws_vpc.main-vpc.id
  name        = "${var.default_resource_name}-worker"
  description = "Security group that allows Worker connections"

  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 10250
    to_port   = 10250
    protocol  = "tcp"
    description = "Kubelet API"
  }

  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 30000
    to_port   = 32767
    protocol  = "tcp"
    description = "NodePort Services"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_key_pair" "node_key" {
  key_name   = var.default_resource_name
  public_key = file(var.node_public_key_path)

  tags = var.tags
}

resource "aws_instance" "cp-node" {
  ami           = var.node_image_id
  instance_type = var.node_instance_type
  key_name      = aws_key_pair.node_key.key_name

  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.ssh.id, aws_security_group.cp.id]

  user_data = <<EOF
#!/bin/bash

mkdir -p /home/ubuntu/logs
sleep 60

sh -x /home/ubuntu/init-kube.sh >> /home/ubuntu/logs/init-kube.log 2>&1
sh -x /home/ubuntu/init-containerd.sh >> /home/ubuntu/logs/init-containerd.log 2>&1
sh -x /home/ubuntu/init-system.sh >> /home/ubuntu/logs/init-system.log 2>&1
sh -x /home/ubuntu/init-cp.sh >> /home/ubuntu/logs/init-cp.log 2>&1
sh -x /home/ubuntu/init-helm.sh >> /home/ubuntu/logs/init-helm.log 2>&1
sh -x /home/ubuntu/init-cp-tools.sh >> /home/ubuntu/logs/init-cp-tools.log 2>&1

sleep 120
sh -x /home/ubuntu/init-cilium.sh >> /home/ubuntu/logs/init-cilium.log 2>&1
EOF

  provisioner "file" {
    source      = "./init-scripts/"
    destination = "/home/ubuntu/"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.node_private_key_path)
      host        = self.public_ip
    }
  }

  tags = merge(var.tags, { Name : "${var.default_resource_name}-cp" })
}

resource "aws_instance" "worker-node" {
  ami           = var.node_image_id
  instance_type = var.node_instance_type
  key_name      = aws_key_pair.node_key.key_name

  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.ssh.id, aws_security_group.worker.id]

  user_data = <<EOF
#!/bin/bash

mkdir -p /home/ubuntu/logs
sleep 60

sh -x /home/ubuntu/init-kube.sh >> /home/ubuntu/logs/init-kube.log 2>&1
sh -x /home/ubuntu/init-containerd.sh >> /home/ubuntu/logs/init-containerd.log 2>&1
sh -x /home/ubuntu/init-system.sh >> /home/ubuntu/logs/init-system.log 2>&1
EOF

  provisioner "file" {
    source      = "./init-scripts/"
    destination = "/home/ubuntu/"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.node_private_key_path)
      host        = self.public_ip
    }
  }

  tags = merge(var.tags, { Name : "${var.default_resource_name}-worker" })
}

resource "aws_route53_zone" "local" {
  name = var.local_domain

  vpc {
    vpc_id = aws_vpc.main-vpc.id
  }

  tags = var.tags
}

resource "aws_route53_record" "cp-node" {
  zone_id = aws_route53_zone.local.zone_id
  name    = "cp.${var.local_domain}"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.cp-node.public_ip]
}

resource "aws_route53_record" "worker-node" {
  zone_id = aws_route53_zone.local.zone_id
  name    = "worker.${var.local_domain}"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.worker-node.public_ip]
}