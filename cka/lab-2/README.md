# CKA - Lab 2

First of all, make sure that `terraform` is installed and that you have configured your aws credentials in `~/.aws/credentials`.

Then the first, time execute:
````
./init.sh
````

You can then initialize the VPC and nodes:
````
terraform apply
````

Don't forget to clear down your resources:
````
terraform destroy
````


````
apiVersion: v1
kind: Config

clusters:
- cluster:
    server: https://k8s.example.org/k8s/clusters/c-xxyyzz
  name: lab2
````

