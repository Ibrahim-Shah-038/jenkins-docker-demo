provider "aws" {
  region = var.aws_region
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

resource "aws_security_group" "allow_all" {
  name = "jenkins-demo-sg"

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

resource "aws_instance" "nodes" {
  count         = 2
  ami           = data.aws_ami.ubuntu.id
  instance_type = var.instance_type
  key_name      = var.key_name
  security_groups = [aws_security_group.allow_all.name]

  user_data = templatefile("${path.module}/user_data.sh", {
    role           = count.index == 0 ? "app" : "monitor"
    app_image      = var.app_image
    frontend_image = var.frontend_image
  })

  tags = {
    Name = count.index == 0 ? "App-Server" : "Monitoring-Server"
  }
}
