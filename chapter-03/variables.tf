variable "list" {
  type = list(any)
  default = [
    true
  ]
}

variable "set" {
  type = set(string)
  default = [
    "test2",
    "test2"
  ]
}

variable "tuple" {
  type = tuple([ string, number ])
  default = [ "value", 0 ]
}

variable "map" {
  type = map(any)
  default = {
    "key1" = "value1", "key2" = "value2"
  }
}

variable "object" {
  type = object({
    name = string
    age = number
  })
  default = {
    name = "value1",
    age = 0,
    test = "test"
  }
}

# variable "validation" {
#   type = string
#   default = "test"

#   validation {
#     condition = can(regex("^value", var.validation))
#     error_message = "not matched"
#   }

#   validation {
#     condition = var.validation == "test1"
#     error_message = "not test1"
#   }
# }

variable "priority" {
  type = string
  default = "test"
}