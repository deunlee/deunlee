# Git Commands
```
git config --global core.eol lf
git config --global core.autocrlf input
git config --global -l
```

```
git init
git config --local user.name "Deun Lee"
git config --local user.email "deunlee@deunlee.com"
git config --local core.eol lf
git config --local core.autocrlf input
git config --local -l
```

```
git init
git config --local user.name "nobody"
git config --local user.email "nobody@nobody.com"
git config --local core.eol crlf
git config --local core.autocrlf false
git config --local -l
```

- feat: 새로운 기능 추가
- fix: 특정 버그 수정
- build: 빌드 관련, 모듈 설치/삭제
- chore: 그 외 자잘한 수정
- ci: CI 관련 설정 수정
- docs: 문서 수정
- style: 코드 스타일 또는 포맷 등 수정
- refactor: 코드 리팩터링
- test: 테스트 코드 수정
- perf: 성능 개선

---
### [필수] 저자별 그룹화 및 커밋 개수 확인
git log --all --format="Author: %an <%ae> / Committer: %cn <%ce>" | sort | uniq -c

---
### [필수] 날짜별 그룹화 및 커밋 개수 확인
git log --all --format="AuthorDate: %ad / CommitDate: %cd" --date=format:"%Y-%m-%d %z"  | sort | uniq -c

---
### [필수] 작성일과 커밋일이 다른 커밋 찾기
git log --format="%ai %ci %s" | awk '$1$2$3 != $4$5$6'

---
### 모든 커밋의 날짜 확인
git --no-pager log --all --format="Author: %ai / Commit: %ci / %s"

---
### 모든 커밋에 대한 패치 파일 생성
git format-patch --root -o patches/

---
### 패치 파일 모두 적용 (두 날짜 동일하게 설정)
git am --committer-date-is-author-date patches/*.patch

---
### 마지막 태그 이후 커밋들을 하나로 합치기
git stash -u
git status
git reset --soft $(git describe --tags --abbrev=0)
git commit -m "Merged at $(date '+%Y-%m-%d %H:%M:%S')"
git stash pop

