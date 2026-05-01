# AGENTS.md

## 기본 응답
- 한국어로 답한다.
- 답변은 기본적으로 짧게 한다.
- 결론을 먼저 말하고, 이유를 한 줄로 덧붙인다.
- 자세한 설명은 사용자가 요청할 때만 한다.

## 작업 방식
- 큰 변경, 설정 변경, 여러 파일 수정은 먼저 계획을 설명한 뒤 진행한다.
- 작은 확인, 읽기, 상태 점검은 바로 수행해도 된다.
- 사용자가 명확히 구현을 요청하면 끝까지 구현하고 검증한다.
- 모르면 추측하지 말고 파일과 설정을 먼저 확인한다.

## 파일 보호
- 기본 작업 위치는 `D:\Agent\Codex`이다.
- `D:\Agent\Codex` 밖의 파일은 사용자 승인 없이 수정하지 않는다.
- 삭제, 이동, 덮어쓰기, 강제 푸시는 사용자 승인 없이 하지 않는다.
- `.git`, `.codex`, `config`, `.env`, key/pem, token/secret/password/credential, `auth.json` 계열은 보호 대상으로 본다.

## 훅 관리
- Codex 훅 설정 파일은 `C:\Users\suna\.codex\hooks.json`에 있다.
- 훅 스크립트는 `D:\Agent\Codex\tools\codex-hooks`에서 관리한다.
- 훅 규칙 내용 변경은 보통 D쪽 `.ps1`만 수정한다.
- 훅 실행 시점, 파일명, 위치를 바꿀 때만 C쪽 `hooks.json` 수정이 필요하다.

## Notion 권한 기준
- `채용공고` DB(`collection://35111b6c-2a63-8082-a59f-000b86242e28`) 안의 내용은 읽기, 편집, 수정, 새 페이지 생성을 허용한다.
- `채용공고` DB 업데이트는 사용자에게 별도 허락을 묻지 않고 진행한다.
- 그 외 Notion DB와 페이지는 읽기만 바로 수행할 수 있다.
- 그 외 Notion DB와 페이지의 생성, 편집, 수정, 이동, 삭제, 댓글 작성은 사용자 승인 후 진행하거나 차단한다.

## 작업일지
- 사용자가 "정리해줘", "오늘 작업 정리해줘", "내가 뭐 했는지 정리해줘"라고 요청하면 `D:\Agent\Codex\WORKLOG.md`를 갱신한다.
- 완료된 작업은 "완료"로, 아직 끝나지 않은 작업은 "진행 중"으로 적는다.
- 기존 기록은 지우지 않고 날짜별 Markdown 형식으로 유지한다.

## 스킬과 자동화
- 자소서 작업은 `D:\Agent\Codex\skills\jaso\SKILL.md`를 우선 따른다.
- 웹소설PD 채용 준비는 `D:\Agent\Codex\skills\webnovel-pf-guide\README.md`를 우선 확인한다.
- 카카오/네이버/리디 크롤러와 러버블 데이터 운영은 `D:\Agent\Codex\skills\webnovel-data-ops\SKILL.md`를 우선 따른다.
- 재사용 스킬/프롬프트는 `D:\Agent\Codex\skills` 아래에 둔다.
- 보조 스크립트와 도구는 `D:\Agent\Codex\tools` 아래에 둔다.
