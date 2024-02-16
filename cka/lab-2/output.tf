output "cp_node_connection_command" {
  value = "ssh -i ~/.aws/k8-certification/node ec2-user@${aws_instance.cp-node.public_dns}"
}