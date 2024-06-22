terraform {
  cloud {
    organization = "hanaldo-tf"
    hostname     = "app.terraform.io" # default

    workspaces {
      name = "terraform-compute"
    }
  }
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

data "terraform_remote_state" "network" {
  backend = "remote"

  config = {
    organization = "hanaldo-tf"
    hostname = "app.terraform.io"
    workspaces = {
      name = "terraform-network"
    }
  }
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      name        = "${var.prefix}-vpc-${var.region}"
      environment = var.environment
    }
  }
}

locals {
  private_key_filename = "${var.prefix}-ssh-key.pem"
}

resource "tls_private_key" "hashicat" {
  algorithm = "RSA"
}

resource "aws_key_pair" "hashicat" {
  key_name   = local.private_key_filename
  public_key = tls_private_key.hashicat.public_key_openssh
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_eip" "hashicat" {
  count = var.ec2_count

  domain   = "vpc"
}

resource "aws_instance" "hashicat" {
  count = var.ec2_count

  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.hashicat.key_name
  associate_public_ip_address = true
  subnet_id                   = data.terraform_remote_state.network.outputs.subnet_id
  vpc_security_group_ids      = [data.terraform_remote_state.network.outputs.sg_id]

  tags = {
    Name = "${var.prefix}-hashicat-instance"
  }
}

resource "aws_eip_association" "hashicat" {
  count = var.ec2_count

  instance_id   = aws_instance.hashicat[count.index].id
  allocation_id = aws_eip.hashicat[count.index].id

  # instance_id   = aws_instance.hashicat.id
  # allocation_id = aws_eip.hashicat.id
}

# We're using a little trick here so we can run the provisioner without
# destroying the VM. Do not do this in production.

# If you need ongoing management (Day N) of your virtual machines a tool such
# as Chef or Puppet is a better choice. These tools track the state of
# individual files and can keep them in the correct configuration.

# Here we do the following steps:
# Sync everything in files/ to the remote VM.
# Set up some environment variables for our script.
# Add execute permissions to our scripts.
# Run the deploy_app.sh script.
resource "null_resource" "configure_cat_app" {
  depends_on = [aws_eip_association.hashicat]

  # triggers = {
  #   build_number = timestamp()
  # }

  count = var.ec2_count

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.hashicat.private_key_pem
    host        = aws_eip.hashicat[count.index].public_ip
    # host        = aws_eip.hashicat.public_ip
  }

  provisioner "file" {
    source      = "files/"
    destination = "/home/ubuntu/"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt -y update",
      "sleep 15",
      "sudo apt -y update",
      "sudo apt -y install apache2",
      "sudo systemctl start apache2",
      "sudo chown -R ubuntu:ubuntu /var/www/html",
      "chmod +x *.sh",
      "PLACEHOLDER=${var.placeholder} WIDTH=${var.width} HEIGHT=${var.height} PREFIX=${var.prefix} ./deploy_app.sh",
      "sudo apt -y install cowsay",
      "cowsay Mooooooooooo!",
    ]
  }
}