# Demo
main.tf is file for task 8 which involved the following steps:

Steps:
Create a VPC
Create 2 Public Subnets
Create 2 Private Subnets
Create an EC2 inside the private subnet with no Public IP.
Create a Security Group for your EC2 with SSH and HTTP ports open.
SSH into EC2 inside the private subnet.


Questions:
How can you access an EC2 in a private subnet? By creating an ec2 instance in the same vpc in public subnet also known as Bastion host. Can also create a NAT gateway in public subnet of same vpc
What network components are required to access a private subnet? Same VPC, 
What is a Bastion Host? The intermediary access point of an EC2 in a private subnet
What is the use-case for private subnets vs public subnets? Private subnet provide security by receiving requests through a load balance and are not directly connected to the internet. 
