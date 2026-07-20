미래에 프로젝트 관리용.
git 관리 정책에 대해서

--- 

main: 상용(배포) 브랜치. 직접 커밋 금지.
intergrator: 메인 보호용 브랜치. 모든 작업 단위 브랜치가 먼저 모이는 곳.
package_[num]: 대규모 작업 단위 브랜치 (예: package_13). 삭제하지 않고 유지.
특정기능: 기능별 세부 작업 브랜치 (예: feature-login). 작업 완료 후 반드시 삭제.

---

# 실제 작업 프로세스 (순서 필수)

### 1.시작하기

최신 코드 가져오기 및 브랜치 생성
새로운 기능을 개발하기 전, 항상 intergrator를 기준으로 최신 코드를 받아와서 브랜치를 만듭니다.

#### 1) intergrator 브랜치로 이동 및 최신화

```bash 
git checkout intergrator
git pull origin intergrator
```

#### 2) [선택] 만약 새로운 package_[num] 브랜치가 필요한 경우에만 생성

```bash 
git checkout -b package_10
git push origin package_10
``` 

#### 3) package_[num] 브랜치를 기준으로 '특정기능' 브랜치 생성 후 이동

```bash 
git checkout -b feature-login
```

----

### 2.개발 중
수시로 pull 받아오기 (충돌 방지)

```bash 
git pull origin package_10
```

---

3.개발 완료

package 브랜치로 통합 및 특정기능 브랜치 삭제
기능 구현이 끝나면 상위 package 브랜치에 코드를 합치고, 임시로 썼던 특정기능 브랜치는 깔끔하게 삭제합니다.


```bash 
# 1) 내 '특정기능' 브랜치에서 변경사항 커밋
git add .
git commit -m "feat: 로그인 기능 구현 완료"

# 2) package_[num] 브랜치로 이동 후 최신화
git checkout package_10
git pull origin package_10

# 3) '특정기능' 브랜치를 package_[num]에 병합(Merge)
git merge feature-login

# 4) 병합된 package_[num] 코드를 원격 저장소에 푸시
git push origin package_10

# 5) [중요] 역할이 끝난 '특정기능' 브랜치 삭제 (package만 살리기)
git branch -d feature-login
```


---
&nbsp;
&nbsp;
&nbsp;
&nbsp;

----
# 상용 배포 프로세스 (Package -> Integrator -> Main)


STEP 1: Package -> Integrator
```Bash
git checkout intergrator
git pull origin intergrator
git merge package_10
git push origin intergrator
```

STEP 2: Integrator -> Main
```Bash
git checkout main
git pull origin main
git merge intergrator
git push origin main
```