packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}
variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "ami_prefix" {
  type    = string
  default = "custom-ubuntu-ami"
}

locals {
  timestamp = regex_replace(timestamp(), "[- TZ:]", "")
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "${var.ami_prefix}-${local.timestamp}"
  instance_type = "t3.micro"
  region        = var.aws_region
  source_ami    = "ami-0547ecbf0e9b4aeb5"
  ssh_username  = "ubuntu"
}

build {
  name = "build-custom-ami"
  sources = [
    "source.amazon-ebs.ubuntu"
  ]

  # Run shell commands to configure the instance
  provisioner "shell" {
    inline = [
      "echo 'Updating system packages...'",
      "sudo apt-get update",
      "sudo apt-get upgrade -y",
      "sudo apt-get install -y nginx docker.io git",
      "sudo systemctl enable nginx"
    ]
  }
}
