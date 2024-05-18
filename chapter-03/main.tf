terraform {
  required_version = "1.8.1"

  required_providers {
    local = {
      source = "hashicorp/local"
      version = "2.5.1"
    }

    docker = {
      source = "kreuzwerker/docker"
      version = "3.0.2"
    }
  }
}

/* 
 * 2. Dependency Test
 */

# resource "local_file" "abc" {
#   content = "terraform 'local_file' resource"
#   filename = "${path.module}/abc.txt" # path.module: file system path that module(directory terraform is run) is run in
# }

# resource "local_file" "implicit_dependency" {
#   content = local_file.abc.content # have dependency for local_file.abc resource
#   filename = "${path.module}/implicit_dependency.txt"
# }

# resource "local_file" "explicit_dependency" {
#   content = "explicit dependency using depends_on"
#   filename = "${path.module}/explicit_dependency.txt"
#   depends_on = [ local_file.abc ] # set dependency explicitly
# }

/*
 * 3. Resource Lifecycle Test
 */

## 3.1. create_before_destroy
# resource "local_file" "abc" {
#   content = "create before destroy is enabled. so content is modified, but deleted because filename is equal."
#   filename = "${path.module}/abc.txt"

#   lifecycle {
#     create_before_destroy = true
#   }
# }

## 3.2. prevent_destroy
# resource "local_file" "abc" {
#   content = "prevent destroy is enabled. so apply is failed because existing file couldn't deleted."
#   filename = "${path.module}/abc.txt"

#   lifecycle {
#     prevent_destroy = true
#   }
# }

## 3.3. ignore_changes
# resource "local_file" "abc" {
#   content = "ignore changes is set, so content is modified but not modified"
#   filename = "${path.module}/abc.txt"

#   lifecycle {
#     ignore_changes = [ content ]
#   }
# }

## 3.4. precondition
# variable "filename" {
#   default = "precondition.txt"
# }

# resource "local_file" "precondition" {
#   content = "precondition is set, so if value isn't matched to condition, apply is failed"
#   filename = "${path.module}/${var.filename}"

#   lifecycle {
#     precondition {
#       condition =  var.filename == "${path.module}/notmatched.txt"
#       error_message = "filename isn't matched"
#     }
#   }
# }

## 3.5. postcondition
# resource "local_file" "postcondition" {
#   content = "postcondition is set, so if value isn't matched to condition, apply is failed"
#   filename = "${path.module}/postcondition.txt"

#   lifecycle {
#     postcondition {
#       condition = self.content == ""
#       error_message = "content isn't empty string"
#     }
#   }
# }

/*
 * 4. Data source
 */

# resource "local_file" "abc" {
#   content = "terraform 'local_file' resource"
#   filename = "${path.module}/abc.txt" # path.module: file system path that module(directory terraform is run) is run in
# }

# # create data source for 'abc' local file
# data "local_file" "abc" {
#   filename = local_file.abc.filename
# }

# # get content of 'abc' local file and create new file using the content
# resource "local_file" "from_data_source" {
#   content = data.local_file.abc.content
#   filename = "${path.module}/from_data_source.txt"
# }

/*
 * 5. Input Variable
 */

## ===> Check Input Variable's value

# output "list" {
#   value = var.list
# }

# output "set" {
#   value = var.set
# }

# output "tuple" {
#   value = var.tuple
# }

# output "map" {
#   value = var.map
# }

# output "object" {
#   value = var.object
# }

# output "priority" {
#   value = var.priority
# }

/*
 * 8. Loop
 */ 


locals {
  list = tolist([ "a", "c" ])
  set = toset([ "a", "c" ])
  map = {
    a = "value a"
    b = "value b"
    c = "value c"
  }
}

## ==> count
# resource "local_file" "test" {
#   count = length(local.list)
#   content = "test ${local.list[count.index]}"
#   filename = "${path.module}/test${count.index}"
# }

## ==> for_each
# resource "local_file" "test" {
#   for_each = local.set # or local.map
#   content = "test ${each.value}"
#   filename = "${path.module}/test${each.key}"
# }

## ==> for
# resource "local_file" "test" {
#   content = jsonencode([ for v in local.list: upper(v) ])
#   filename = "${path.module}/test.txt"
# }

# resource "local_file" "test" {
#   for_each = toset([ for v in local.list: upper(v) ])
#   content = "test ${each.value}"
#   filename = "${path.module}/test${each.key}.txt"
# }

# resource "local_file" "test2" {
#   content = jsonencode({
#     for v in local.list: v => upper(v)
#     if v == "a"
#   })
#   filename = "${path.module}/test2.txt"
# }

## ==> Dynamic
locals {
  ports = [
    {
      internal = 1234
      external = 1234
    },
    {
      internal = 5678
      external = 5678
    }
  ]
}

provider "docker" {
  # Configuration options
}

# Pulls the image
resource "docker_image" "ubuntu" {
  name = "ubuntu:20.04"
}

# Create a container
resource "docker_container" "ubuntu" {
  image = docker_image.ubuntu.image_id
  name  = "ubuntu"
  command = [ "tail",  "-f" ]

  dynamic "ports" {
    for_each = local.ports
    content {
      internal = ports.value.internal
      external = ports.value.external
    }
  }
}