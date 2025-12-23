variable "aws_region" {
  default = "eu-north-1"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "key_name" {
  default = "jenkins-key"
}

variable "app_image" {}
variable "frontend_image" {}
