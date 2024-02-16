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

Don't forget to teardown your resources:
````
terraform destroy
````

