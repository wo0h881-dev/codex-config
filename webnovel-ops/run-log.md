## 2026-06-19

- status: blocked before diagnostics
- failed command: `Get-Location`
- retry count: 1
- next smaller command to try: `pwd`
- note: stopped immediately after repeated `windows sandbox: helper_unknown_error: setup refresh had errors`

## 2026-08-03

- status: fixed crawler parser issue
- scope: Lovable dashboard crawler check for Kakao, Naver, Ridi
- checks:
  - Naver: `qa_crawl_check.py naver` collected 20 items, required-field failures 0
  - Kakao: `qa_crawl_check.py kakao` found 50 ranking content links
  - Ridi: `qa_crawl_check.py ridi` collected romance 11, rofan 11, fantasy 11, bl 12, required-field failures 0
- issue found: Ridi list parser returned 0 items because the title/card selector changed from `a.fig-w1hthz`
- fix: updated Ridi parser to group cards by `/books/{id}` links and use fallback selectors for title, author, publisher, and genre
- verification: `python -m py_compile main.py naver.py ridi.py qa_crawl_check.py` passed

## 2026-08-17

- status: Lovable local runtime reset complete
- issue found: prior `npm.cmd run test` and `npm.cmd run build` processes remained running; custom Vite IPv6 host/port/HMR settings were reset.
- fixes: stopped stale Node processes, removed untracked Vite logs, and restored the default Vite plugin/alias configuration.
- checks: `npm.cmd run test` passed (1 test); `npm.cmd run build` passed.
- note: existing crawler data and dashboard UI changes were preserved; no commit or push requested.
