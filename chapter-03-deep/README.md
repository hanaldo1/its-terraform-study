# terraform_data 조금 더 파보기
> - terraform_data: https://developer.hashicorp.com/terraform/language/resources/terraform-data
> - resource lifecycle > replace_triggered_by: https://developer.hashicorp.com/terraform/language/meta-arguments/lifecycle#replace_triggered_by

## 1. provisioner 와 함께 사용 (null_resource 대체)
terraform_data 는 프로비저너를 실행하기 위해 사용할 수 있으면서, null_resource 와는 다르게 별도의 프로바이더 없이 사용이 가능함.
- null_resource 의 경우, hashicorp/null 프로바이더 설치 필요

### 테스트
>  `terraform_data-provisioner.tf` 코드 참고
```
Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # terraform_data.provisioner will be created
  + resource "terraform_data" "provisioner" {
      + id = (known after apply)
    }

Plan: 1 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes 

terraform_data.provisioner: Creating...
terraform_data.provisioner: Provisioning with 'local-exec'...
terraform_data.provisioner (local-exec): Executing: ["/bin/sh" "-c" "echo test"]
terraform_data.provisioner (local-exec): test
terraform_data.provisioner: Creation complete after 0s [id=27d813ad-27b6-4cad-f7c5-665dc1dd5d21]
```
: terraform apply 시 local-exec 프로비저너가 실행되어 `echo test` 커맨드를 실행한 결과 확인 가능

## 2. replace_triggered_by 와 함께 사용
- 테라폼 1.2 버전부터 리소스 블럭에 lifecycle 블럭 - replace_triggered_by 인수를 사용하여 특정 조건에 리소스가 교체되도록 할 수 있음
- 하지만 `replace_triggered_by` 에는 리소스 주소(ex. `local_file.abc`, `local_file.abc.<속성>`) 만 사용이 가능하기 때문에, 원래라면 local 이나 입력 변수를 사용할 수 없으나 terraform_data 를 통해 리소스화 하여 local 이나 입력 변수 에 의해 교체(replace) 트리거 가능

### 테스트
>  `terraform_data-replace_triggered_by.tf` 코드 참고

- 주석 처리 된 코드를 보면, 원래라면 revision 변수와 같이 리소스가 아닌 데이터는 lifecycle.replace_triggered_by 에 사용 할 수 없기 때문에 바로 사용 시 syntax 에러가 발생함.

    #### 주석 처리 된 코드로 terraform plan 시 에러
    ```
    ╷
    │ Error: Invalid reference in replace_triggered_by expression
    │ 
    │   on terraform_data-replace_triggered_by.tf line 21, in resource "local_file" "abc":
    │   21:     replace_triggered_by = [var.revision]
    │ 
    │ Only resources, count.index, and each.key may be used in replace_triggered_by.
    ╵
    ╷
    │ Error: Invalid replace_triggered_by expression
    │ 
    │   on terraform_data-replace_triggered_by.tf line 21, in resource "local_file" "abc":
    │   21:     replace_triggered_by = [var.revision]
    │ 
    │ Missing resource reference in replace_triggered_by expression.
    ```

- 따라서 주석처리 되지 않은 코드처럼, terraform_data 블럭에 input 으로 revision 변수를 지정함으로써 리소스화 하여 replace_triggered_by 에 사용할 수 있음
- `terraform apply` 이후, 다시 `terraform apply -var 'revision=2'` 로 변수 값을 변경하게 되면 아래와 같이 리소스가 교체 되는 실행 계획을 확인할 수 있음

    #### terraform_data 에 정의한 입력 변수 변경 시 replace 트리거
    ```
    Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
    ~ update in-place
    -/+ destroy and then create replacement

    Terraform will perform the following actions:

    # local_file.abc will be replaced due to changes in replace_triggered_by
    -/+ resource "local_file" "abc" {
        ~ content_base64sha256 = "n4bQgYhMfWWaL+qgxVrQFaO/TxsrC4Is0V1sFbDwCgg=" -> (known after apply)
        ~ content_base64sha512 = "7iaw3Ur350mqGo7jwQrpkj9hiYB3Lkc/iBml1JQODbJ6wYX4oOHV+E+IvIh/1nsUNzLDBMxfqa2Ob1f1ACio/w==" -> (known after apply)
        ~ content_md5          = "098f6bcd4621d373cade4e832627b4f6" -> (known after apply)
        ~ content_sha1         = "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3" -> (known after apply)
        ~ content_sha256       = "9f86d081884c7d659a2feaa0c55ad015a3bf4f1b2b0b822cd15d6c15b0f00a08" -> (known after apply)
        ~ content_sha512       = "ee26b0dd4af7e749aa1a8ee3c10ae9923f618980772e473f8819a5d4940e0db27ac185f8a0e1d5f84f88bc887fd67b143732c304cc5fa9ad8e6f57f50028a8ff" -> (known after apply)
        ~ id                   = "a94a8fe5ccb19ba61c4c0873d391e987982fbbd3" -> (known after apply)
            # (4 unchanged attributes hidden)
        }

    # terraform_data.replacement will be updated in-place
    ~ resource "terraform_data" "replacement" {
            id     = "d3751172-7b92-0bf4-9166-fda5c0f2a57d"
        ~ input  = 1 -> "2"
        ~ output = 1 -> (known after apply)
        }

    Plan: 1 to add, 1 to change, 1 to destroy.
    ```