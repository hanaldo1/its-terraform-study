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