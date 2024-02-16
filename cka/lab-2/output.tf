output "cp_node_connection_command" {
  value = "ssh -i ~/.aws/k8-certification/node ubuntu@${aws_instance.cp-node.public_dns}"
}