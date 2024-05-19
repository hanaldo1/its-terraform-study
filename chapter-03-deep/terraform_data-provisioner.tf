terraform {
  required_version = "1.8.1"

  required_providers {
    local = {
      source = "hashicorp/local"
      version = "2.5.1"
    }
  }
}

resource "terraform_data" "provisioner" {
  provisioner "local-exec" {
    command = "echo test"
  }
}