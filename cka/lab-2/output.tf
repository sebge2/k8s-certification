output "cp_node_connection_command" {
  value = "ssh -o StrictHostKeyChecking=no -i ~/.aws/k8-certification/node ubuntu@${aws_instance.cp-node.public_dns}"
}

output "worker_node_connection_command" {
  value = "ssh -o StrictHostKeyChecking=no -i ~/.aws/k8-certification/node ubuntu@${aws_instance.worker-node.public_dns}"
}

output "cp_api_endpoint" {
  value = "${aws_instance.cp-node.public_dns}:6443"
}