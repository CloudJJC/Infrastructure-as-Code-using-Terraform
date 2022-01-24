#Infrastructure as Code: The following steps can be used to provision an Amazon EC2 instance using Terraform

#Create a VPC
resource "aws_vpc" "cloudjjc_vpc" {
  cidr_block           = "10.123.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    name = "dev"
  }
}

#Create a subnet
resource "aws_subnet" "cloudjjc_public_subnet" {
  vpc_id                  = aws_vpc.cloudjjc_vpc.id
  cidr_block              = "10.123.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-west-2a"

  tags = {
    name = "dev_public"
  }
}

#Create an internet gateway to grant access into the subnet
resource "aws_internet_gateway" "cloudjjc_internet_gateway" {
  vpc_id = aws_vpc.cloudjjc_vpc.id

  tags = {
    name = "dev_igw"
  }
}

#Create a route table
resource "aws_route_table" "cloudjjc_public_route_table" {
  vpc_id = aws_vpc.cloudjjc_vpc.id

  tags = {
    name = "dev_public_route_table"
  }
}


resource "aws_route" "default_route" {
  route_table_id         = aws_route_table.cloudjjc_public_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.cloudjjc_internet_gateway.id
}


resource "aws_route_table_association" "cloudjjc_public_association" {
  subnet_id      = aws_subnet.cloudjjc_public_subnet.id
  route_table_id = aws_route_table.cloudjjc_public_route_table.id
}


#Create a security group and define ingress and egress conditions
#I have specified an open IP address for ingress cidr blocks just as an illustration.
#Adopt principle of least privilege by specifying the IP of your local computer and add '/32'
#To get yoour local IP address, run 'ipconfig' on command prompt, if using a windows machine
resource "aws_security_group" "cloudjjc_security_group" {
  name        = "dev_security_group"
  description = "dev sec group"
  vpc_id      = aws_vpc.cloudjjc_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

#Create a key pair
resource "aws_key_pair" "cloudjjc_auth" {
  key_name   = "cloudjjckey"
  public_key = file("~/.ssh/cloudjjckey.pub")
}

#Provision the Amazon EC2 instance 
resource "aws_instance" "cloudjjc_instance" {
  instance_type          = "t2.micro"
  ami                    = data.aws_ami.server_ami.id
  key_name               = aws_key_pair.cloudjjc_auth.id
  vpc_security_group_ids = [aws_security_group.cloudjjc_security_group.id]
  subnet_id              = aws_subnet.cloudjjc_public_subnet.id


  #This inceases volume size. AWS gives a default size of 8GiB
  root_block_device {
    volume_size = 10
  }

  #You could create a name for your instance by creating a tag
  tags = {
    name = "cloudjjc-instance"
  }
}