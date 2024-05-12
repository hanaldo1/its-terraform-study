# 잇츠 스터디 크루 1기 - Terraform Beginners
`테라폼으로 시작하는 IaC` 책을 기반으로 테라폼 활용방법을 익히기 위한 실습한 연습 코드들을 모아둔 레포

## 개요
- 스터디 목표: `테라폼으로 시작하는 IaC` 책 완독
- 개인 목표:
  - 테라폼을 이용한 개인 쿠버네티스 클러스터 구축
  - (Optional) Terraform Associate (003) 자격증 취득

## 세팅
- macOS 13.0 (Apple M2)
- asdf: 0.12.0
  - Go: 1.21.7 (darwin/arm64)
  - Terraform: 1.8.1 (darwin/arm64)
- Git: 2.41.0
- VSCode: 1.86.2
  - HashiCorp Terraform: 2.30.1
  - HashiCorp HCL: 0.4.0

### terraform cli 세팅
- plugin 캐시 디렉토리 설정
```
plugin_cache_dir = "$HOME/.terraform.d/plugin-cache"
```