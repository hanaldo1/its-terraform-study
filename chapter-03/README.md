# `테라폼으로 시작하는 IaC` 3장 내용 요약

## 1. terraform 기본 명령어 (init, plan, validate, apply)
- 테라폼 모듈을 초기화 하기 위해서는 init 명령어 사용 (필요 프로바이더 설치 등 진행)
  - 만약 프로바이더 버전 변경이 필요한 경우, `-upgrade` 옵션과 함께 실행
- CI/CD 파이프라인에서 validate 명령어와 같이 사용하면 좋은 옵션
  - `-no-color`: 콘솔 출력 결과에서 색상 표기 제거 (색상 표기 문자 표시되지 않도록)
  - `-json`: 실행 결과 JSON 출력
- CI/CD 파이프라인에서 plan 명령어와 같이 사용하면 좋은 옵션
  - `-detailed-exitcode`: plan 결과를 시스템 코드($?) 로 출력해줌 (0: 변경 사항 X-성공, 1: 오류 존재, 2: 변경사항 O-성공)
- 기본적으로 apply 시 실행 계획을 같이 보여주지만, plan 시  `-out=<파일 이름>` 옵션을 통해 생성한 파일을 apply 시 지정해주면 실행 계획 표시 없이 즉시 적용 진행함
- destroy 에 대한 실행 계획은 plan 명령어에 `-destroy` 옵션을 통해서 확인
- destroy 의 경우 apply 명령어에 `-destroy` 옵션을 통해서도 가능
- apply 및 destroy 의 경우, -auto-approve 옵션을 통해 실행 계획 없이 즉시 반영 가능

## 2. HCL
- 표현식 (주석, boolean, 숫자, 문자열, 함수, 삼항 연산자)
- terraform 블럭
  - 테라폼 구성 (테라폼 버전, 프로바이더 버전)
    
    ```
    terraform {
      required_version = "..."
      
      required_providers {
        <provider> = {
          source = ".."
          version = "..."
        }
      }

      # Terraform Cloud 사용 시 필요   
      cloud {}

      # State 저장소
      backend <저장소 타입> {}
    }
    ```

    - 버전의 경우 시맨틱 버전(`<Major>.<Minor>.<Patch>`) 지원
    - 버전 명시 시 연산자 지원 (=, !=, >/>=/<=/<, ~>)
      - ~> 의 경우 가장 낮은 자리수에 대해서만 증가 허용 (ex. ~> 1.0.0 의 경우, 1.0.x 허용 / 1.x 허용하지 않음)

- 백엔드 블럭
  - 협업 등의 목적으로 상태 공유를 위해 State(상태 파일) 의 저장 위치를 지정할 때 사용 (단, 하나의 백엔드만 허용)
  - 백엔드 설정을 변경한 경우, init 을 통해 재설정이 필요. 이때 -migrate-state 및 -reconfigure 옵션을 통해 기존 상태파일을 마이그레이션 할지 (기본), 삭제하고 새로 초기화 할지 선택 가능

## 3. 리소스
### 리소스 블럭
```
resource <리소스 유형> <이름> {
  <인수> = <값>
}
```
- 리소스 유형의 경우, `<프로바이더 이름>_<유형 이름>` 으로 구성 됨. (ex. resource "local_file" 의 경우, 프로바이더 이름은 local, 유형 이름은 file)
- 같은 리소스 유형의 경우 동일한 이름을 선언할 수 없음 (이름 = 식별자 역할)
- 어떠한 인수도 정의하지 않는 경우에도 중괄호(`{}`) 는 작성 필요
- 리소스는 프로바이더에 종속적이기 때문에 terraform 블럭에 프로바이더를 명시적으로 작성하지 않아도 terraform init 시 필요 프로바이더가 설치됨

### 종속성
- 기본적으로 B 리소스에서 A 리소스를 참조할 경우, 암시적으로 종속성이 생김
- 명시적으로 종속성을 설정할 필요가 있을 경우 (ex. 특정 순서에 맞게 리소스 프로비저닝이 필요한 경우), 리소스 정의 `depends_on` 인수를 사용
- `terraform graph` 명령어를 통해 리소스간의 연관 관계 확인 가능

  > `테라폼으로 시작하는 IaC` 91 페이지에서 종속성 유무에 따른 리소스 생성 그래프 확인 가능

### 리소스 참조
- `<리소스 유형>.<이름>.<인수>` : 리소스 생성 시 정의하는 값 (Arguments)
- `<리소스 유형>.<이름>.<속성>` : 리소스 생성 이후 획득 가능한 값 (Attributes)

### 리소스 라이프 사이클
- create_before_destroy: 리소스 변경 시 재 생성(replace) 해야 하는 경우, 먼저 새 리소스 생성 후 이전 리소스를 삭제함 (기본 동작은 false = 삭제 후 생성)
- prevent_destroy: 리소스가 삭제되는 것을 방지
- ignore_changes: 특정 인수의 값이 변경되어도 리소스 변경이 이루어지지 않도록 할 때 사용 (즉, ignore_changes 에 명시한 인수가 변경되어도 plan/apply 시 테라폼은 변경사항이 없다고 판단)
- precondtion / postcondition : 리소스 생성 전 및 후 검증 조건 설정

## 4. 데이터 소스
테라폼으로 정의하지 않은 외부 리소스 및 데이터를 참조할 때 사용

### 데이터 블럭
```
data <데이터 소스 유형> <이름> {
  <인수> = <값>
}
```
- 데이터 소스 유형의 경우, `<프로바이더 이름>_<유형 이름>` 으로 구성 됨. (ex. data "local_file" 의 경우, 프로바이더 이름은 local, 유형 이름은 file)
- 같은 데이터 소스 유형의 경우 동일한 이름을 선언할 수 없음 (이름 = 식별자 역할)
- 어떠한 인수도 정의하지 않는 경우에도 중괄호(`{}`) 는 작성 필요

### 데이터 참조
- `data.<데이터 소스 유형>.<이름>.<속성>` : 외부 리소스 및 데이터에서 획득 가능한 값 (Attributes) (ex. 기 정의된 AWS VPC 리소스의 CIDR 값)

## 5. 입력 변수
### 변수 선언
```
variable '<이름>' {
  <인수> = <값>
}
```
- 변수 블록 이름은 모듈 내에서 고유해야 함
- `var.<이름>` 로 참조
- 민감한 값을 포함한 변수의 경우, 정의 시 `sensitive = true` 를 추가 (실행 계획에 변수 값이 출력되지 않음)
- 입력 변수 값 지정 우선순위는 다음과 같음 (낮음 < 높음)
  - CLI 에서 입력 < variable 블록 default 값 < TF_VAR_<이름> 환경변수 < terraform.tfvars 파일 < *.auto.tfvars 파일 <  *.auto.tfvars.json 파일 < CLI -var 및 -var-file 옵션

### 변수 유형
- any (모든 유형 허용)

원시(Primitive) 타입
- string
- number
- bool

컬렉션(Collection) 유형
- list
- map
- set

구조(Structural) 유형
- object
- tuple

#### list 와 set 차이
- list 및 set 을 정의하는 방법은 비슷하지만, set 의 경우 값을 기준으로 정렬
- 또한 list 의 경우 인덱스를 통해서 특정 요소를 참조할 수 있으나, set 은 인덱스 및 키를 통해 특정 요소를 참조할 수 없음.
  - set 타입의 변수에서 특정 요소 참조 시도 시, `Elements of a set are identified only by their value and don't have any separate index or key to select with, so it's only possible to perform operations across all elements of the set.` 와 같은 에러 발생
  ```
  variable "list" {
    type = list(string)
    default = [
      "test2",
      "test1"
    ]
  }
  => [ "test2", "test1" ]
  => var.list.0 으로 특정 요소 참조 가능

  variable "set" {
    type = set(string)
    default = [
      "test2",
      "test1"
    ]
  }
  => [ "test1", "test2" ] # 값 기준 정렬 됨
  => var.set.0 과 같이 특정 요소 참조 불가능
  ```

- set 의 경우, 고유한 값의 집합을 정의해야 할 때 주로 사용

  ```
  variable "list" {
    type = list(string)
    default = [
      "test2",
      "test2"
    ]
  }
  => [ "test2", "test2" ]

  variable "set" {
    type = set(string)
    default = [
      "test2",
      "test2"
    ]
  }
  => [ "test2" ]
  ```

#### list 와 tuple 차이
- list 의 경우 모든 요소는 동일한 타입이어야 함 (크기는 가변적)
  ```
  variable "list" {
  type = list(any)
    default = [
      true,
      0
    ]
  }
  => 두 요소의 유형이 다르기 때문에 에러 발생
  ```

- tuple 의 경우 여러 타입을 혼합해서 정의가 가능하지만, tuple 변수에 정의된 유형 집합과 실제 값의 개수가 일치해야 하며 유형 또한 일치해야 함

    ```
    variable "tuple1" {
      type = tuple([ string, number ])
      default = [ "value", 0 ] # success 
    }

    variable "tuple2" {
      type = tuple([ string, number ])
      default = [ "value", "value" ]
    }
    => 두번째 요소의 유형이 number 가 아니기 때문에 에러 발생

    variable "tuple3" {
      type = tuple([ string, number ])
      default = [ "value", 0, 0 ]
    }
    => 타입 정의 시 명시한 요소 개수와 실제 값 개수가 다르기 때문에 에러 발생
    ```

#### map 과 object 차이
- map 의 경우 모든 요소는 동일한 타입이어야 함 (크기는 가변적)
  - 키와 값은 : 또는 = 으로 구분 가능
  - 키에 한해서 숫자로 시작하는 경우를 제외하고는 "" 는 생략 가능
  - 한 줄로 값을 정의할 경우 각 요소는 `,` 로 구분되어야 하며, 멀티라인의 경우 개행으로도 구분 가능

  ```
  variable "map" {
    type = map(string)
    default = { key1 = "value1", key2 = "value2" } # 키 quote 생략 가능
    
    default = { "key1" = "value1", "key2" = "value2" } # single line
    
    default = {
      "key1" = "value1"
      "key2" = "value2"
    } # multi line
  }

  variable "map2" {
    type = map(any)
    default = {
      "key1" = true, "key2" = 0
    }
  }
  => 두 요소 값 유형이 다르기 때문에 에러 발생
  ```

- object 의 경우 여러 타입을 혼합해서 정의가 가능하지만, 정의된 스키마와 실제 값이 일치해야 하며 유형 또한 일치해야 함

  ```
  variable "object1" {
    type = object({
      name = string
      age = number
    })
    default = {
      name = "value1",
      age = 0
    }
  } # success

  variable "object2" {
    type = object({
      name = string
      age = number
    })
    default = {
      name = "value1",
      age = "test"
    }
  }
  => age 값이 정의된 유형과 다르기 때문에 에러 발생

  variable "object3" {
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
  => 에러가 발생하지 않지만 스키마에 정의되지 않은 값은 무시됨
  ```

### 변수 유효성 검사
- 변수 정의 시 validation 블럭을 추가하여 입력 값에 대한 유효성 검증 가능
- can 과 regex 함수를 함께 사용하여 정규식을 통한 검증도 가능

  ```
  variable "validation" {
    type = string
    default = "test"

    validation {
      condition = can(regex("^value", var.validation))
      error_message = "not matched"
    }

    validation {
      condition = var.validation == "test1"
      error_message = "not test1"
    }
  }
  ```

### 변수 값 지정 파일
#### terraform.tfvars, *.auto.tfvars
```
<변수 이름> = <값>
```

#### *.auto.tfvars.json
```
{
  "<변수 이름>": <값>
}
```

## 6. local
### local 선언
```
locals {
  <이름> = <값> # 상수, variable, 리소스 속성으로 값 정의 가능

  # ex) name = "test"
  # ex) name = var.test
  # ex) name = local_file.a.content
}
```
- local 이름은 모듈 내에서 고유해야 하며, 입력 변수(variable) 과는 다르게 외부에서 값을 지정해줄 수는 없음
- `local.<이름>` 으로 참조하며, 선언된 모듈 내에서만 참조 가능
  - 반대로 같은 모듈 내라면 다른 파일에 정의되어있는 local 도 참조 가능

## 7. output
### output 선언
```
output "<이름>" {
  value = <값>
}
```
- 기본적으로 프로비저닝 후의 결과(ex. 리소스 속성(attribute) 를 확인하기 위해서 사용)
- 또한 다른 모듈에서 해당 모듈의 특정 데이터에 참조해야 할 때 사용 (즉, output 값은 다른 모듈에서 참조 가능)
- 리소스 속성(attribute) 의 경우 프로비저닝 된 후에 알 수 있기 때문에 plan 시에는 정확한 값이 출력되지는 않음 (apply 이후에 확인 가능)
- `sensitive = true` 인수를 추가하면, 실제 값은 출력되지 않음

## 8. 반복문
### count
```
locals {
  list = tolist([ "a", "c" ])
}

resource "local_file" "test" {
  count = length(local.list)
  content = "test ${local.list[count.index]}"
  filename = "${path.module}/test${count.index}"
}

=> local_file.test[0], local_file.test[1], local_file.test[2] 리소스 생성
=> test0, test1, test2 파일 생성
```
- 선언된 정수만큼 리소스를 생성하며, `count.index` 를 통해 인덱스 값을 참조할 수 있음
- count 수를 정의하기 위해 list 입력변수 를 사용한 경우, 중간 값을 삭제하면 해당 리소스만 제거되는 것이 아닌 이후 인덱스의 리소스 모두 제거되거나 교체(replace) 되는 등 영향을 받음 (사용 시 주의 필요)

### for_each
```
locals {
  set = toset([ "a", "c" ])
  map = {
    a = "value a"
    b = "value b"
  }
}

resource "local_file" "test" {
  for_each = local.set # or local.map
  content = "test ${each.value}"
  filename = "${path.module}/test${each.key}"
}
```
- map 또는 set 을 기준으로, 선언된 키 값 개수 만큼 리소스를 생성하며, `each.key` 및 `each.value` 를 통해 각각 키 및 값을 참조할 수 있음 (set 의 경우, key 와 value 값 동일)
- count 와 다르게 for_each 는 인덱스가 아닌 키 값을 사용하기 때문에, set 및 map 의 값을 변경하여도 변경한 값에 대한 리소스만 영향을 받음

### for
```
locals {
  list = tolist([ "a", "c" ])
}

resource "local_file" "test" {
  content = jsonencode([ for v in local.list: upper(v) ])
  filename = "${path.module}/test.txt"
}

resource "local_file" "test2" {
  content = jsonencode({for v in local.list: v => upper(v) })
  filename = "${path.module}/test2.txt"
}
```
- for 의 경우 복합 형식 값의 형태를 변환하는데 사용
- list 의 경우 인수가 하나인 경우(`for v in ...`) 값을, 두개인 경우(`for i, v in ...`) 각각 인덱스 및 값을 참조할 수 있음
- map 의 경우 두개의 인수(`for k, v in ...`)로 각각 키 및 값을 참조할 수 있음
- for 문을 [] 로 감싸면 tuple, {} 로 감싸면 object 을 반환
  - object 의 경우 => 기호를 통해 키-값 쌍을 구분
  - _[확인 해보기] 단 object 로 반환하는 경우 키 값은 고유해야 하기 때문에 `...` 를 이용해 그룹화 필요_

- if 문을 추가하여 특정 조건에 맞는 값만 필터링 가능
  ```
  resource "local_file" "test2" {
    content = jsonencode({
      for v in local.list: v => upper(v)
      if v == "a"
    })
    filename = "${path.module}/test2.txt"
  }
  ```

### dynamic
```
resource "<리소스 유형>" "<이름>" {
  <인수> = <값>
  ...
  
  dynamic "<리소스 블럭-인수>" {
    for_each = ...
    content {
      <인수 블럭-인수> = <값>
    }
  }
}
```
- 리소스 자체를 여러개 생성하는 것이 아닌, 리소스 선언 내 구성 블럭을 반복하여 정의 해야하는 경우 사용
  - EX. AWS Security Group Rule, Docker container port

- 실제로 정의해야 하는 인수를 dynamic 블럭 이름으로, 반복할 값을 for_each 에, 실제 인수 블럭 내에 정의해야 하는 내용을 content 블럭으로 정의
  - 리소스 블럭에서 for_each 사용 시 `each.key` 및 `each.value` 를 사용 가능한 것처럼, dynamic 블럭에서 for_each 사용 시 `<dynamic 블럭 이름>.key` 및 `<dynamic 블럭 이름>.value` 로 값 참조 가능

  ### Ex. Docker Container 생성
  ```
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

  provider "docker" {}

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
  ```

## 9. 조건식
```
<조건 문> ? <참일 경우 결과> : <거짓일 경우 결과>

=> local.a == "A" ? "true" : "false"
```

## 10. 함수
- 테라폼에서는 upper, join 과 같이 값의 유형을 변경하거나 조합할 수 있는 내장함수를 지원함
  - 자세한 함수 리스트는 [링크](https://developer.hashicorp.com/terraform/language/functions) 참고
- 다만, 사용자 정의 함수는 지원하지 않음
- 함수의 결과 및 동작을 확인하기 위해 terraform console 을 사용할 수 있음 (python REPL과 유사)

## 11. 프로비저너

## 12. null_resource

## 13. moved

## 14. 시스템 환경변수
### TF_LOG
- 테라폼 sterr 로그 레벨 (trace, debug, info, warn, error, off)
  - 환경변수 없는 경우 off 와 동일
- 다음 환경변수들과 같이 사용할 수 있음
  - TF_LOG_PATH: 로그 출력 파일 경로
  - TF_LOG_CORE: 테라폼 자체 코어 로그 레벨 정의
  - TF_LOG_PROVIDER: 테라폼 프로바이더 로그 레벨 정의

### TF_INPUT (-input 옵션)
- false 또는 0으로 설정 시, 입력 변수에 대한 입력을 받지 않음

### TF_VAR_<name>
- 입력 변수 `<name>` 에 대한 값 지정

### TF_CLI_ARGS, TF_CLI_ARGS_<subcommand>
- cli 및 cli 서브 커맨드 실행 시 추가할 인수(ex. -input) 정의

### TF_DATA_DIR
- 작업 디렉토리 별 데이터 저장 위치 (default: `.terraform`)
  - 민약 실행마다 해당 환경변수 값이 달라지는 경우, 기 설치된 모듈/프로바이더를 찾지 못하므로 사용 시 주의 필요