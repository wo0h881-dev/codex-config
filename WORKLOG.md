# Worklog

## 2026-04-29

### 완료
- Codex 안전장치 훅 구성을 만들었다.
- 위험 명령 차단, 보호 파일 수정 차단, 파일 수정 알림, Notion 쓰기 확인 훅을 추가했다.
- 자소서 자동화 `jaso`의 `SKILL.md` 한글 깨짐을 UTF-8로 복구했다.
- `jaso` 자소서 자동화를 역할별 에이전트 구조로 분리했다.
- 루트 폴더를 목적별로 정리했다: 재사용 스킬은 `skills`, 보조 스크립트는 `tools`.
- `C:\Users\suna\.codex\hooks.json`은 유지하고, 훅 실행 경로만 `D:\Agent\Codex\tools\codex-hooks`로 갱신했다.
- 중복된 `C:\Users\suna\.codex\hooks` 폴더를 제거했다.
- `block-dangerous-command.ps1`을 완화해 일반 읽기 명령은 승인 없이 통과하도록 바꿨다.
- 쓰기, 삭제, 이동, 네트워크, 위험 명령은 계속 차단하도록 유지했다.
- `.env`, key/pem, token/secret/password/credential, auth.json 계열은 읽기/검색도 차단하도록 보강했다.

### 현재 구조
- `D:\Agent\Codex\AGENTS.md`
- `D:\Agent\Codex\WORKLOG.md`
- `D:\Agent\Codex\skills\jaso`
- `D:\Agent\Codex\skills\webnovel-pf-guide`
- `D:\Agent\Codex\tools\codex-hooks`

### 확인 결과
- `hooks.json`은 유효한 JSON이다.
- `hooks.json`은 C쪽 훅 스크립트를 참조하지 않는다.
- 훅 스크립트는 D쪽 `tools\codex-hooks` 아래 파일을 실행한다.
- 일반 파일 읽기 명령은 통과한다.
- `.env`, `.env.local`, `*.key`, `*.pem`, `*secret*`, `*token*`, `auth.json` 읽기는 차단된다.
- `Remove-Item`, `Move-Item`, `Invoke-WebRequest`는 차단된다.

### 다음에 이어서 할 일
- 훅 스크립트 이름이나 위치를 다시 바꿀 때만 `C:\Users\suna\.codex\hooks.json` 수정이 필요하다.

## 2026-05-01

### 완료
- 웹소설 데이터 운영 체계를 설계하고 `skills\webnovel-data-ops` 스킬을 추가했다.
- `webnovel-ops\watchlist.md`, `field-contract.md`, `run-log.md` 공유 메모리 파일을 만들었다.
- 카카오, 네이버, 리디 랭킹/목록 URL을 watchlist에 반영했다.
- 매주 월요일 15:00에 실행되는 `Web Novel Crawler Weekly QA` 자동화를 만들었다.
- `web-novel-crawler` 저장소를 로컬로 클론했다.
- 수동 QA를 1회 실행해 리디/네이버 샘플은 통과, 카카오는 댓글수/총회차 파싱 문제가 있음을 확인했다.
- 카카오 검증용 `manual-qa.mjs`, `kakao-probe.mjs`를 추가했다.
- 카카오 크롤러 `main.py`에 목록 링크 fallback과 `전체 N` 기반 회차/댓글수 추출 fallback을 적용했다.
- `web-novel-crawler` 전용 `.venv`를 만들고 필요한 Python 패키지를 설치했다.
- `.venv` Python으로 문법 검사, 의존성 import, Playwright 브라우저 실행을 확인했다.
- `.gitignore`를 추가해 `.venv`, 캐시, 로컬 출력물, `.env` 계열 파일이 커밋되지 않도록 했다.

### 진행 중
- 카카오 크롤러 수정은 로컬 파일에는 적용됐지만, `git add` 승인이 거절되어 커밋/PR은 아직 진행하지 않았다.
- Codex 기본 세션에서는 `python`, `py`, `python3` 명령이 바로 잡히지 않았지만, WindowsApps Python 전체 경로와 승인 권한으로 실행 가능함을 확인했다.
- Python 문법 검사와 의존성 확인을 통과했고, `main.py` 실제 실행까지 완료했다.
- `WEBAPP_URL`이 없어 Google WebApp 전송은 건너뛰었고, 로컬 JSON 파일 생성은 완료됐다.

### 다음에 이어서 할 일
- 앞으로 크롤러 실행은 `D:\Agent\Codex\web-novel-crawler\.venv\Scripts\python.exe`만 사용한다.
- `WEBAPP_URL`은 대화에 직접 붙여넣지 말고 사용자 환경변수나 비커밋 `.env` 방식으로 관리한다.
- 실행 통과 후 카카오 수정 브랜치를 커밋하고 PR 생성 방식을 정한다.

## 2026-08-03

### 완료
- 식물 관리 기록용 모바일 웹앱 `plant-log`를 만들었다.
- Next.js 16, TypeScript, Tailwind CSS, PWA 구조로 구성했다.
- 사진 업로드, 미리보기, 이미지 압축, 여러 장 선택 기능을 구현했다.
- 식물 선택 UI를 만들고, 최근 선택 식물 저장 기능을 추가했다.
- Notion 식물 관찰일지 DB에 사진, 식물명, 분류, 관찰일지, 관찰일을 저장하도록 연결했다.
- 사진은 Notion `사진` 속성과 페이지 본문 이미지 블록에 모두 들어가도록 수정했다.
- 식물명은 상세 식물명만 저장하고, 대분류는 Notion `분류` select 속성으로 분리 저장하도록 고쳤다.
- 식물목록 DB를 Notion에서 불러오도록 `/api/plants`를 추가했다.
- 식물목록 DB 속성은 `식물명` title, `대분류` select 기준으로 읽게 했다.
- 식물페이지 UI에서 대분류는 `식물 선택` 오른쪽에 표시하고, 목록에는 상세 식물명만 보이게 정리했다.
- GitHub 저장소 `wo0h881-dev/plant-log`에 커밋/푸시했다.
- Vercel 배포용 환경변수 설정 흐름을 정리했다.

### 확인 결과
- `npm.cmd run lint` 통과.
- `npm.cmd run build` 통과.
- GitHub push 완료.
- 식물DB 내용 변경은 재배포 없이 새로고침으로 반영되는 구조다.

### 다음에 이어서 할 일
- Vercel 환경변수 `NOTION_PLANTS_DATABASE_ID`가 식물목록 DB ID로 들어갔는지 확인한다.
- 식물목록 DB와 관찰일지 DB 모두 Notion Integration `shortcut`에 연결되어 있어야 한다.
- 식물페이지에서 새 기록을 저장해 Notion 속성과 본문 사진이 모두 들어가는지 최종 확인한다.

## 2026-10-23

### 완료
- `plant-log`의 Cloudflare Workers 배포 설정을 GitHub `main` 브랜치에 반영했다.
- 원격 변경사항을 로컬 커밋과 리베이스한 뒤 GitHub에 푸시했다.
- Cloudflare Workers에 식물 앱을 최초 배포했다.
- Cloudflare Production 환경에 Notion 토큰과 식물·관찰·물주기·관리 DB 및 데이터 소스 ID를 등록했다.
- 배포 주소 `https://plant-log.wo0h881.workers.dev`에서 Notion 식물 목록과 선택 옵션이 정상적으로 조회되는 것을 확인했다.
- 식물 목록 API가 `source: notion`으로 응답하고, 기존 100개 조회 제한 없이 페이지네이션하도록 되어 있음을 확인했다.

### 확인 결과
- GitHub 커밋 `7a98ea3`까지 푸시됐다.
- 식물 목록과 옵션 API의 Notion 연동이 정상 작동한다.
- Cloudflare 대시보드에서 환경변수를 추가한 후 배포하면 기존 앱에 바로 적용된다.

### 주의사항
- 로컬 `npm.cmd run deploy:vinext`는 현재 Cloudflare 대시보드 설정과 충돌해 원격 환경변수나 바인딩을 덮어쓸 수 있으므로 사용하지 않는다.
- 당분간 재배포는 Cloudflare 대시보드에서 진행한다.
- `next/image` 최적화는 비활성화 상태라 큰 이미지가 많으면 로딩이 느려질 수 있다.
- Vinext는 Next.js 완전 호환이 아니므로 Next.js 업데이트나 새로운 서버 기능 추가 후에는 Cloudflare 빌드와 주요 API를 다시 확인한다.
