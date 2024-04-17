# Latest Available Cluster Definition

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

Don't forget to clear down your resources:
````
terraform destroy
````


## Links

- [DNS Resolution](https://kubernetes.io/docs/tasks/administer-cluster/dns-debugging-resolution/)
- [Cilium Routing](https://docs.cilium.io/en/stable/network/concepts/routing/)
