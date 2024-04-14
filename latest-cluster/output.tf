output "cp_node_connection_command" {
  value = "ssh -o StrictHostKeyChecking=no -i ~/.aws/k8-certification/node ubuntu@${aws_instance.cp-node.public_dns}"
}

output "worker_nodes_connection_command" {
  value = [for worker in aws_instance.worker-nodes : format("ssh -o StrictHostKeyChecking=no -i ~/.aws/k8-certification/node ubuntu@%s", worker.public_dns)]
}

output "vault_connection_command" {
  value = "ssh -o StrictHostKeyChecking=no -i ~/.aws/k8-certification/node ubuntu@${aws_instance.vault.public_dns}"
}

output "cp_api_endpoint" {
  value = "${aws_instance.cp-node.public_dns}:6443"
}