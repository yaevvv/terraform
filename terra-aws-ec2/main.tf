provider "aws" {
  profile = "default"
  region  = "us-east-1"
}

resource "aws_instance" "ec2" {
  ami           = "ami-2757f631"
  instance_type = "t2.micro"
  subnet_id = "subnet-08afcdc257bb05b6f"
  tags = {
    Name = "${var.name}"
  }  
}
