variable "revision" {
  default = 1
}

# resource "local_file" "abc" {
#   content = "test"
#   filename = "${path.module}/abc.txt"

#   lifecycle {
#     replace_triggered_by = [var.revision]
#   }
# }
# ====> replace_triggerd_by 에는 local 및 input variable 을 바로 사용할 수 없기 때문에 위 코드는 에러 발생

resource "terraform_data" "replacement" {
  input = var.revision
}

resource "local_file" "abc" {
  content = "test"
  filename = "${path.module}/abc.txt"

  lifecycle {
    replace_triggered_by = [terraform_data.replacement]
  }
}
# ====> revision 변수를 terraform_data 로 리소스화 하여 사용