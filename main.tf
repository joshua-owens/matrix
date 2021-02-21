terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.26.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "3.57.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.0.1"
    }
  }
  required_version = "~> 0.14"

  backend "remote" {
    organization = "jowens"

    workspaces {
      name = "matrix"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

resource "random_pet" "sg" {}

resource "aws_instance" "web" {
  ami                    = "ami-830c94e3"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.web-sg.id]

  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF
}

resource "aws_security_group" "web-sg" {
  name = "${random_pet.sg.id}-sg"
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "web_address" {
  value = "${aws_instance.web.public_dns}:8080"
}

variable "gcp_project_id" {
  default = ""
}

variable "gcp_credentials" {
  default = {}
}

provider "google" {
  project = var.gcp_project_id
  region  = "us-central1"
  zone    = "us-central1-c"
}

resource "google_dns_managed_zone" "dev" {
  name        = "matrix-subdomain"
  dns_name    = "matrix.jowens.dev."
  description = "Sub domain for matrix configuration"
  forwarding_config {
    target_name_servers {
      ipv4_address = "${aws_instance.web.public_dns}:8080"
    }
  }
}
