param()

$ErrorActionPreference = 'SilentlyContinue'

$inputText = [Console]::In.ReadToEnd()
$jsonText = $inputText
if ([string]::IsNullOrWhiteSpace($jsonText)) { $jsonText = '' }
$toolText = @($env:TOOL_NAME, $env:tool_name, $env:CODEX_TOOL_NAME, $jsonText) -join "`n"

$readOnlyPatterns = @(
  '(?i)_search\b',
  '(?i)_fetch\b',
  '(?i)_get_\w+\b',
  '(?i)_query_\w+\b',
  '(?i)search',
  '(?i)fetch',
  '(?i)get',
  '(?i)query'
)
foreach ($pattern in $readOnlyPatterns) {
  if ($toolText -match $pattern -and $toolText -notmatch '(?i)(create|update|move|duplicate|comment|delete|replace|append|apply_template)') {
    exit 0
  }
}

$writePatterns = @(
  '(?i)_notion_(create|update|move|duplicate)\w*',
  '(?i)_notion_create_comment\b',
  '(?i)(create|update|move|duplicate|comment|delete|replace_content|update_content|apply_template)'
)
$allowedWriteTargets = @(
  'collection://35111b6c-2a63-8082-a59f-000b86242e28',
  '35111b6c-2a63-8082-a59f-000b86242e28',
  '35111b6c2a6380f4bfe8e3c50731ee45',
  '채용공고'
)
$allowedChildPageIds = @(
  '35111b6c2a63812babf4ee1dccbaa640', # 제이트리미디어 - 남성향 장르소설/웹소설 PD
  '35111b6c2a6381babfd0c961dc1fb75a', # 브리드컴퍼니 - 판타지/무협 웹소설·장르소설 PD
  '35111b6c2a63819f972ce8b5e4a5a088', # 엠스토리허브 - 웹소설 PD 경력직
  '35111b6c2a63818caeaae2f84369a951', # 테일크루 - 웹소설 PD
  '35111b6c2a638114a5e6c14a544de951', # 리디 - 로맨스 웹소설 PD
  '35111b6c2a638121bf05ecf41206e877', # 리디 - BL 웹소설/웹툰 PD
  '35111b6c2a6381d1925ff9e09ba538a8', # 가람미디어허브 - 웹소설 PD 모집(로맨스/로판/BL)
  '35111b6c2a638171a1c4e4acf6a602e4'  # 청어람 - 로맨스/BL 웹소설 편집PD
)

function Normalize-NotionId {
  param([string]$Value)
  if ([string]::IsNullOrWhiteSpace($Value)) { return '' }
  return ($Value -replace '[^0-9a-fA-F]', '').ToLowerInvariant()
}

$normalizedToolText = Normalize-NotionId $toolText
foreach ($pattern in $writePatterns) {
  if ($toolText -match $pattern) {
    # 채용공고 DB와 그 하위 페이지 업데이트는 사전 승인 없이 허용한다.
    foreach ($target in $allowedWriteTargets) {
      if ($toolText -match [regex]::Escape($target)) {
        exit 0
      }
    }
    foreach ($pageId in $allowedChildPageIds) {
      if ($normalizedToolText -match [regex]::Escape((Normalize-NotionId $pageId))) {
        exit 0
      }
    }
    Write-Error "Notion 쓰기 작업 차단/확인 필요: $($Matches[0])"
    exit 2
  }
}

exit 0
