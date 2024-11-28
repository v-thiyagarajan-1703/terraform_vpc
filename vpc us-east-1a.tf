terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "us-east-1"
}

# Create a VPC
resource "aws_vpc" "Myvpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "mypubsub" {
  vpc_id     = aws_vpc.Myvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "MYPUBSUB"
  }
}

resource "aws_subnet" "myprtsub" {
  vpc_id     = aws_vpc.Myvpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "MYPRTSUB"
  }
}

resource "aws_internet_gateway" "myigw" {
  vpc_id = aws_vpc.Myvpc.id

  tags = {
    Name = "IGW"
  }
}

resource "aws_route_table" "mypubrt" {
  vpc_id = aws_vpc.Myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myigw.id
  }


  tags = {
    Name = "MYPUBRT"
  }
}

resource "aws_route_table_association" "assmypub" {
  subnet_id      = aws_subnet.mypubsub.id
  route_table_id = aws_route_table.mypubrt.id
}

resource "aws_eip" "myeip" {
  domain   = "vpc"
}

resource "aws_nat_gateway" "mynat" {
  allocation_id = aws_eip.myeip.id
  subnet_id     = aws_subnet.mypubsub.id

  tags = {
    Name = "MY-NAT"
  }
}

resource "aws_route_table" "myprtrt" {
  vpc_id = aws_vpc.Myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.mynat.id
  }


  tags = {
    Name = "MYPUBRT"
  }
}

resource "aws_route_table_association" "assmyprt" {
  subnet_id      = aws_subnet.myprtsub.id
  route_table_id = aws_route_table.myprtrt.id
}

resource "aws_security_group" "mypubsecurity" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.Myvpc.id
 
 ingress {
    description    ="TLS form VPC"
    from_port      = 0
    to_port        = 65535
    protocol       = "tcp"
    cidr_blocks    =["0.0.0.0/0"]  
 }
 
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

 tags = {
    Name = "MY-PUBS-G"
  }
}

resource "aws_security_group" "myprtsecurity" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.Myvpc.id
 
 ingress {
    description    ="TLS form VPC"
    from_port      = 0
    to_port        = 65535
    protocol       = "tcp"
    cidr_blocks    =["0.0.0.0/0"]  
 }
 
egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

 tags = {
    Name = "MY-PRTS-G"
  }
}

resource "aws_instance" "pub-instance" {
    ami                             = "ami-0166fe664262f664c"
    instance_type                   = "t2.micro"
    availability_zone               = "us-east-1a"
    associate_public_ip_address     = "true"
    vpc_security_group_ids          = [aws_security_group.mypubsecurity.id]
    subnet_id                       = aws_subnet.mypubsub.id
    key_name                        ="dev.ppt" 
  
}

resource "aws_instance" "prt-instance" {
    ami                             = "ami-0166fe664262f664c"
    instance_type                   = "t2.micro"
    availability_zone               = "us-east-1c"
    associate_public_ip_address     = "false"
    vpc_security_group_ids          = [aws_security_group.myprtsecurity.id]
    subnet_id                       = aws_subnet.myprtsub.id
    key_name                        ="dev.ppt" 
  
}