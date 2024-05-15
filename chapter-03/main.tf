terraform {
  required_version = "1.8.1"

  required_providers {
    local = {
      source = "hashicorp/local"
      version = "2.5.1"
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

output "priority" {
  value = var.priority
}