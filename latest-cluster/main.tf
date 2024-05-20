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
  domain     = "vpc"
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
    from_port = 22
    to_port   = 22
    protocol  = "TCP"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
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
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.node.id]
    description     = "Allow all inside the cluster"
  }

  ingress {
    from_port       = 6443
    to_port         = 6443
    protocol        = "TCP"
    security_groups = [aws_security_group.vault.id, aws_security_group.cp-proxy.id]
    description     = "Allow all from vault"
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
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.node.id]
    description     = "Allow all inside the cluster"
  }

  ingress {
    from_port   = 30000
    to_port     = 32767
    protocol    = "TCP"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
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

resource "aws_security_group" "cp-proxy" {
  vpc_id      = aws_vpc.main-vpc.id
  name        = "${var.default_resource_name}-cp-proxy"
  description = "Security group that allows connections to Control Plane proxy"

  ingress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.node.id]
    description     = "Allow all inside the cluster"
  }

  ingress {
    from_port   = 9999
    to_port     = 9999
    protocol    = "TCP"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    description = "Stats"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = var.tags
}

resource "aws_security_group" "vault" {
  vpc_id      = aws_vpc.main-vpc.id
  name        = "${var.default_resource_name}-vault"
  description = "Security group for vault server"

  ingress {
    from_port       = 8200
    to_port         = 8200
    protocol        = "TCP"
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    description     = "Allow vault inside cluster"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_key_pair" "node_key" {
  key_name   = var.default_resource_name
  public_key = file(var.node_public_key_path)

  tags = var.tags
}

data "template_file" "main_cp_node" {
  template = file("./init-node-scripts/init-all-main-cp.sh")

  vars = {
    numberCpNodes = sum([var.number_additional_cp, 1]),
    numberWorkerNodes = var.number_workers
  }
}

resource "aws_instance" "main_cp-node" {
  ami           = var.node_image_id
  instance_type = var.node_instance_type
  key_name      = aws_key_pair.node_key.key_name

  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.ssh.id, aws_security_group.node.id, aws_security_group.cp-node.id]

  user_data = data.template_file.main_cp_node.rendered

  provisioner "file" {
    source      = "./init-node-scripts/"
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

  tags = merge(var.tags, { Name : "${var.default_resource_name}-cp-0" })
}

data "template_file" "additional_cp_node" {
  template = file("./init-node-scripts/init-all-additional-cp.sh")

  vars = {
  }
}

resource "aws_instance" "additional_cp-nodes" {
  count         = var.number_additional_cp

  ami           = var.node_image_id
  instance_type = var.node_instance_type
  key_name      = aws_key_pair.node_key.key_name

  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.ssh.id, aws_security_group.node.id, aws_security_group.cp-node.id]

  user_data = data.template_file.additional_cp_node.rendered

  provisioner "file" {
    source      = "./init-node-scripts/"
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

  tags = merge(var.tags, { Name : "${var.default_resource_name}-cp-${sum([count.index, 1])}" })
}

data "template_file" "worker" {
  template = file("./init-node-scripts/init-all-worker.sh")

  vars = {
    numberWorkerNodes = var.number_workers
  }
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

  user_data = data.template_file.worker.rendered

  provisioner "file" {
    source      = "./init-node-scripts/"
    destination = "/home/ubuntu/"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.node_private_key_path)
      host        = self.public_ip
    }
  }

  ebs_block_device {
    device_name = "/dev/sda1"
    volume_size = 16
  }

  tags = merge(var.tags, { Name : "${var.default_resource_name}-worker" })
}

data "template_file" "cp_proxy" {
  template = file("./init-cp-proxy-scripts/init-all.sh")

  vars = {
    numberCpNodes = sum([var.number_additional_cp, 1]),
  }
}

resource "aws_instance" "cp_proxy" {
  ami           = var.cp_proxy_image_id
  instance_type = var.cp_proxy_instance_type
  key_name      = aws_key_pair.node_key.key_name

  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [
    aws_security_group.ssh.id, aws_security_group.cp-proxy.id
  ]

  user_data = data.template_file.cp_proxy.rendered

  provisioner "file" {
    source      = "./init-cp-proxy-scripts/"
    destination = "/home/ubuntu/"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.node_private_key_path)
      host        = self.public_ip
    }
  }

  tags = merge(var.tags, { Name : "${var.default_resource_name}-cp-proxy" })
}

data "template_file" "vault" {
  template = file("./init-vault-scripts/init-all.sh")

  vars = {
  }
}

resource "aws_instance" "vault" {
  ami           = var.vault_image_id
  instance_type = var.vault_instance_type
  key_name      = aws_key_pair.node_key.key_name

  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [
    aws_security_group.ssh.id, aws_security_group.vault.id
  ]

  user_data = data.template_file.vault.rendered

  provisioner "file" {
    source      = "./init-vault-scripts/"
    destination = "/home/ubuntu/"

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file(var.node_private_key_path)
      host        = self.public_ip
    }
  }

  tags = merge(var.tags, { Name : "${var.default_resource_name}-vault" })
}

resource "aws_route53_zone" "local" {
  name = var.local_domain

  vpc {
    vpc_id = aws_vpc.main-vpc.id
  }

  tags = var.tags
}

resource "aws_route53_record" "proxy_cp_node" {
  zone_id = aws_route53_zone.local.zone_id
  name    = "cp.${var.local_domain}"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.cp_proxy.private_ip]
}

resource "aws_route53_record" "main_cp_node" {
  zone_id = aws_route53_zone.local.zone_id
  name    = "cp-0.${var.local_domain}"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.main_cp-node.private_ip]
}

resource "aws_route53_record" "additional-cp-nodes" {
  count = var.number_additional_cp

  zone_id = aws_route53_zone.local.zone_id
  name    = "cp-${sum([count.index, 1])}.${var.local_domain}"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.additional_cp-nodes[count.index].private_ip]
}

resource "aws_route53_record" "worker-nodes" {
  count = var.number_workers

  zone_id = aws_route53_zone.local.zone_id
  name    = "worker-${count.index}.${var.local_domain}"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.worker-nodes[count.index].private_ip]
}

resource "aws_route53_record" "vault" {
  zone_id = aws_route53_zone.local.zone_id
  name    = "vault.${var.local_domain}"
  type    = "A"
  ttl     = "300"
  records = [aws_instance.vault.private_ip]
}