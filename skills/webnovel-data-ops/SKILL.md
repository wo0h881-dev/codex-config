---
name: webnovel-data-ops
description: Use when maintaining the Korean web novel crawler and Lovable dashboard data flow for Kakao, Naver, and Ridi rankings, parser breakages, required field QA, promotions, scheduled checks, or PR-oriented fixes.
---

# Web Novel Data Ops

Use this skill for web novel data operations across:

- Crawler repo: `https://github.com/wo0h881-dev/web-novel-crawler.git`
- Dashboard repo/folder: `D:\Agent\Codex\Lovable_Dashboard`
- Shared ops memory: `D:\Agent\Codex\webnovel-ops`
- Crawler Python: `D:\Agent\Codex\web-novel-crawler\.venv\Scripts\python.exe`

## Role Routing

Act as the manager first. Classify every request before changing code.

- **Crawler parser owner**: Use for Kakao/Naver/Ridi scraping, parser failures, changed DOM structure, missing rank/list data, or promotion extraction.
- **Data QA owner**: Use for validating required fields and deciding whether a parser fix is needed.
- **Lovable owner**: Use only when the user explicitly asks to change dashboard UI, scoring, pages, labels, filtering, or display behavior.
- **PR/automation owner**: Use after code changes to isolate branches, summarize diffs, run checks, and prepare PR-ready output.

Default priority is crawler first. Kakao parser stability is highest priority because Kakao changes structure often.

## Required Field Contract

Crawler output must preserve existing downstream schema and include valid values for:

- title
- author
- publisher
- rank
- views or rating/review count, depending on platform
- comment count
- total episode count
- promotion info: wait-free/free episodes/event banner/event notice text when available

Treat empty strings, nulls, zeroes caused by parse failure, `#ERROR!`, `-`, or obviously swapped fields as QA failures.

## Workflow

1. Read `D:\Agent\Codex\webnovel-ops\watchlist.md` for platform list/ranking URLs.
2. Inspect the relevant repo before guessing. For crawler work, clone or open `web-novel-crawler`; for dashboard work, inspect `Lovable_Dashboard`.
3. Use the crawler repo `.venv` Python for crawler checks; avoid the WindowsApps Python alias except for one-time venv bootstrap.
4. Reproduce the issue against the smallest affected platform/sample.
5. Fix parser logic with stable selectors, text-based fallbacks, and defensive normalization.
6. Run field QA against the required contract.
7. If dashboard code changed, run `npm run test` and `npm run build` in `Lovable_Dashboard`.
8. Record result in `D:\Agent\Codex\webnovel-ops\run-log.md`.
9. Prepare a PR summary. Do not create a PR if no code/data change is needed.

## Lovable Rules

Lovable usually reflects crawler data automatically when the existing schema is preserved. Only edit Lovable when the user asks for UI/scoring/page behavior, such as:

- show Ridi comments directly
- exclude Ridi comments from rank/trend score
- add or modify a dashboard page
- change table/card/detail display

## Scheduled Check Rules

For scheduled checks:

- Run every Monday at 15:00 Asia/Seoul.
- Check crawler first, using watchlist URLs.
- Use `D:\Agent\Codex\web-novel-crawler\.venv\Scripts\python.exe` for Python execution.
- Do not print or store `WEBAPP_URL`; only verify whether it exists.
- Validate all required fields.
- If failures are found, fix crawler and prepare a PR.
- If no failures are found, append a short success note to the run log and stop.
- Never silently ignore failures; log the failing platform, URL, missing fields, and next action.
