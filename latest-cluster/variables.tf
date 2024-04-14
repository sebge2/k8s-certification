variable "default_resource_name" {
  default = "k8s-certification"
}

variable "tags" {
  description = "Tags to add on resources"
  default     = {
    Name : "k8s-certification"
  }
  type = map(string)
}

variable "aws_region" {
  description = "The name of the AWS region"
  default     = "eu-central-1"
  type        = string
}

variable "aws_main_availability_zone" {
  description = "The name of the main AWS region"
  default     = "a"
  type        = string
}

variable "aws_secondary_availability_zone" {
  description = "The name of the secondary AWS region"
  default     = "b"
  type        = string
}

variable "node_instance_type" {
  description = "The EC2 instance type of nodes"
  default     = "t2.medium"
}

variable "node_image_id" {
  description = "AMI of node"
  default     = "ami-0faab6bdbac9486fb"
}

variable "node_public_key_path" {
  description = "The file Path to the node public SSH key."
  type        = string
  default     = "~/.aws/k8-certification/node.pub"
}

variable "node_private_key_path" {
  description = "The file Path to the node public SSH key."
  type        = string
  default     = "~/.aws/k8-certification/node"
}

variable "local_domain" {
  description = "Local DNS domain"
  type    = string
  default = "sfeir.local"
}

variable "number_workers" {
  description = "Number of worker nodes"
  type = number
  default = 1
}