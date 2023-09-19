provider "aws" {
  region     = "us-east-2"
  access_key = "AKIA5NLSAKZPFNFFZTNZ"
  secret_key = "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"
}

#create a vpc 
resource "aws_vpc" "prodvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "production_vpc"
  }
}

#create a subnet

resource "aws_subnet" "prodsubnet1" {
  vpc_id     = "${aws_vpc.prodvpc.id}"
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "prod_subnet"
  }
}

#create internet gateway

resource "aws_internet_gateway" "gw" {
  vpc_id     = "${aws_vpc.prodvpc.id}"

  tags = {
    Name = "new-IGW"
  }
}

#create a route table

resource "aws_route_table" "prodroute" {
  vpc_id  = "${aws_vpc.prodvpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "RI"
  }
}

#associate subnet with a route table

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.prodsubnet1.id
  route_table_id = aws_route_table.prodroute.id
}

#create sec group

resource "aws_security_group" "allow_web" {
  name        = "allow_web"
  description = "Allow webserver inbound traffic"
  vpc_id = aws_vpc.prodvpc.id

  ingress {
    description = "Web Traffic from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
  ingress {
    description = "HTTP Port"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH Port"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Security_Group_allow_tls"
  }
}

# use data source to get a registered amazon linux 2 ami
data "aws_ami" "ubuntu" {

    most_recent = true

    filter {
        name   = "name"
        values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
    }

    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }

    owners = ["099720109477"]
    }

    # launch the ec2 instance and install website
resource "aws_instance" "ec2_instance" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.small"
  subnet_id      = aws_subnet.prodsubnet1.id
  vpc_security_group_ids = [aws_security_group.allow_web.id]
  key_name               = "ohio"
  # user_data            = file("install_jenkins.sh")

  tags = {
    Name = "jenkins_server"
  }
}


# an empty resource block
resource "null_resource" "name" {

  # ssh into the ec2 instance 
  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/Downloads/ohio.pem")
    host        = aws_instance.ec2_instance.public_ip
  }

  # copy the install_jenkins.sh file from your computer to the ec2 instance 
  provisioner "file" {
    source      = "install_jenkins.sh"
    destination = "/tmp/install_jenkins.sh"
  }

  # set permissions and run the install_jenkins.sh file
  provisioner "remote-exec" {
    inline = [
        "sudo chmod +x /tmp/install_jenkins.sh",
        "sh /tmp/install_jenkins.sh",
    ]
  }

  # wait for ec2 to be created
  depends_on = [aws_instance.ec2_instance]
}

# print the url of the jenkins server
output "website_url" {
  value     = join ("", ["http://", aws_instance.ec2_instance.public_dns, ":", "8080"])
}


# launch the ec2 instance and install website
resource "aws_instance" "ecs_instance" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "t2.small"
  subnet_id      = aws_subnet.prodsubnet1.id
  vpc_security_group_ids = [aws_security_group.allow_web.id]
  key_name = "ohio"
   user_data = "${file("install_tomcat.sh")}"

  tags = {
    Name = "tomcat_server"
  }
}

#resource "aws_instance" "first_instanc" {
 # ami           = "ami-024e6efaf93d85776" # us-east-2
#  instance_type = "t2.micro"
 # vpc_security_group_ids = [aws_security_group.allow_web.id]
 # subnet_id      = aws_subnet.prodsubnet1.id
 # key_name = "ohio"
 # availability_zone = "us-east-2a"
 # count = 3

#  tags = {
#    Name = "web server"
#}
#} 