provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "main-vpc" {
  cidr_block           = "192.168.0.0/16"
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
  cidr_block        = "192.168.1.0/24"
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
  domain_name         = var.local_domain
  domain_name_servers = ["AmazonProvidedDNS"]

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

resource "aws_security_group" "node" {
  vpc_id      = aws_vpc.main-vpc.id
  name        = "${var.default_resource_name}-node"
  description = "Security group for cluster nodes"
}

resource "aws_security_group" "cp-node" {
  vpc_id      = aws_vpc.main-vpc.id
  name        = "${var.default_resource_name}-cp-node"
  description = "Security group that allows Control plane connections"

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    security_groups = [aws_security_group.node.id]
    description     = "Allow all inside the cluster"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_security_group" "worker-node" {
  vpc_id      = aws_vpc.main-vpc.id
  name        = "${var.default_resource_name}-worker-node"
  description = "Security group that allows Worker connections"

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    security_groups = [aws_security_group.node.id]
    description     = "Allow all inside the cluster"
  }

  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
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

data "template_file" "cp" {
  template = file("./init-scripts/setup-cp.sh")

  vars = {
    numberWorkerNodes = var.number_workers
  }
}

resource "aws_instance" "cp-node" {
  ami           = var.node_image_id
  instance_type = var.node_instance_type
  key_name      = aws_key_pair.node_key.key_name

  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.ssh.id, aws_security_group.node.id, aws_security_group.cp-node.id]

  user_data = data.template_file.cp.rendered

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

  provisioner "file" {
    source      = var.node_private_key_path
    destination = "/home/ubuntu/node.key"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.node_private_key_path)
      host        = self.public_ip
    }
  }

  tags = merge(var.tags, { Name : "${var.default_resource_name}-cp" })
}

resource "aws_instance" "worker-nodes" {
  count         = var.number_workers
  ami           = var.node_image_id
  instance_type = var.node_instance_type
  key_name      = aws_key_pair.node_key.key_name

  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [
    aws_security_group.ssh.id, aws_security_group.node.id, aws_security_group.worker-node.id
  ]

  user_data = <<EOF
#!/bin/bash

mkdir -p /home/ubuntu/logs
sleep 120

sh -x /home/ubuntu/init-kube.sh >> /home/ubuntu/logs/init-kube.log 2>&1
sh -x /home/ubuntu/init-containerd.sh >> /home/ubuntu/logs/init-containerd.log 2>&1
sh -x /home/ubuntu/init-system.sh >> /home/ubuntu/logs/init-system.log 2>&1
sh -x /home/ubuntu/init-nfs-client.sh >> /home/ubuntu/logs/init-nfs-client.log 2>&1
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
  records = [aws_instance.cp-node.private_ip]
}

resource "aws_route53_record" "worker-nodes" {
  count = var.number_workers

  zone_id = aws_route53_zone.local.zone_id
  name    = "worker-${count.index}.${var.local_domain}"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.worker-nodes[count.index].private_ip]
}