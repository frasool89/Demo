terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  
}

  required_version = ">= 1.2.0"
}

provider "aws" {
  region  = "us-east-1"
}


resource "aws_vpc" "tf-vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true # Internal domain name
  enable_dns_hostnames = true # Internal host name

  tags = {
    Name = "tf-vpc"
  }
}




resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.tf-vpc.id

  tags = {
    Name = "tf-gw"
  }
}
resource "aws_subnet" "tf-public" {
  # Number of public subnet is defined in vars
  count = 2

 
  cidr_block              = "10.0.${count.index + 2}.0/24"
  vpc_id                  = aws_vpc.tf-vpc.id
  map_public_ip_on_launch = true # This makes the subnet public

  tags = {
    Name = "tf-public-subnet-${count.index}"
  }
}

resource "aws_subnet" "tf-private-subnet" {
  # Number of private subnet is defined in vars
  count = 2

  cidr_block        = "10.0.${count.index}.0/24"
  vpc_id            = aws_vpc.tf-vpc.id

  tags = {
    Name = "tf-private-subnet-${count.index}"
  }
}




resource "aws_instance" "Bastion" {
  ami           = "ami-079db87dc4c10ac91"
  instance_type = "t2.micro"
  depends_on = [aws_internet_gateway.gw] 
  subnet_id     = "subnet-0bc9020e6f0896655"
   associate_public_ip_address = "true"
 }


resource "aws_instance" "Private" {
  ami           = "ami-079db87dc4c10ac91"
  instance_type = "t2.micro"
 
  subnet_id     = "subnet-0acf6f9383877f3b2"
  key_name      ="FRdemo"

 }
