provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "main-vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true
  tags  = var.tags
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.main-vpc.id
  tags  = var.tags
}

resource "aws_eip" "ip_cp_node" {
  vpc        = true
  instance = aws_instance.cp-node.id
}

resource "aws_route_table" "route-table-test-env" {
  vpc_id = aws_vpc.main-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gateway.id
  }

  tags =var.tags
}
resource "aws_route_table_association" "subnet-association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.route-table-test-env.id
}

resource "aws_subnet" "public_subnet" {
  cidr_block = "10.0.101.0/24"
  vpc_id = aws_vpc.main-vpc.id
  availability_zone = "${var.aws_region}${var.aws_main_availability_zone}"
  tags  = var.tags
}

resource "aws_security_group" "ssh" {
  vpc_id      = aws_vpc.main-vpc.id
  name        = var.default_resource_name
  description = "Security group that allows SSH connections"

  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]
    from_port = 22
    to_port = 22
    protocol = "tcp"
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
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
  ami           = "ami-0faab6bdbac9486fb"
  instance_type = var.node_instance_type
  key_name      = aws_key_pair.node_key.key_name

  associate_public_ip_address = true
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.ssh.id]

  user_data = file("${path.module}/node-init.sh")

  tags = var.tags
}