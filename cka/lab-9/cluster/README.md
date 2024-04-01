# CKA - Lab 9

First of all, make sure that `terraform` is installed and that you have configured your aws credentials in `~/.aws/credentials`.

Then the first, time execute:
````
./init.sh
````

You can then initialize the VPC and nodes:
````
terraform apply
````

Wait few minutes before the node is ready:
````
kubectl get node
````

Then you can generate the join command to execute on the worker node:
````
# Execute on cp-node, the result of this command is a command that must be executed on worker node
sh join-command-helper.sh 
````

Don't forget to clear down your resources:
````
terraform destroy
````


## Links

- [DNS Resolution](https://kubernetes.io/docs/tasks/administer-cluster/dns-debugging-resolution/)
- [Cilium Routing](https://docs.cilium.io/en/stable/network/concepts/routing/)