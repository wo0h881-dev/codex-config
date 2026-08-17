param()

$ErrorActionPreference = 'SilentlyContinue'

$inputText = [Console]::In.ReadToEnd()
$jsonText = $inputText
if ([string]::IsNullOrWhiteSpace($jsonText)) { $jsonText = '' }
$toolText = @($env:TOOL_NAME, $env:tool_name, $env:CODEX_TOOL_NAME, $jsonText) -join "`n"

$dynamicAllowlistPath = Join-Path $PSScriptRoot 'notion-allowlist.json'

$employmentRootId = '34c11b6c2a6380f0bbecc72bfe773f70'
$staticAllowedIds = @(
  $employmentRootId,
  # Jobs database under employment page.
  '35111b6c2a6380f4bfe8e3c50731ee45',
  '35111b6c2a638082a59f000b86242e28',
  # Cover letter experience database under employment page.
  '8575be5ac396407f8e3b1c2338ea60c4',
  '12f48c1e9fb7437ba7174ec89dda8d71'
)
$staticAllowedText = @(
  'collection://35111b6c-2a63-8082-a59f-000b86242e28',
  'collection://12f48c1e-9fb7-437b-a717-4ec89dda8d71',
  '35111b6c-2a63-8082-a59f-000b86242e28',
  '12f48c1e-9fb7-437b-a717-4ec89dda8d71'
)

function Normalize-NotionId {
  param([string]$Value)
  if ([string]::IsNullOrWhiteSpace($Value)) { return '' }
  return ($Value -replace '[^0-9a-fA-F]', '').ToLowerInvariant()
}

function Load-DynamicAllowedIds {
  if (-not (Test-Path -LiteralPath $dynamicAllowlistPath)) { return @() }
  try {
    $raw = Get-Content -LiteralPath $dynamicAllowlistPath -Raw
    if ([string]::IsNullOrWhiteSpace($raw)) { return @() }
    $obj = $raw | ConvertFrom-Json
    if ($obj -and $obj.ids) { return @($obj.ids) }
  } catch {}
  return @()
}

function Test-AllowedTarget {
  param([string]$Text)

  $normalizedText = Normalize-NotionId $Text
  foreach ($target in $staticAllowedText) {
    if ($Text -match [regex]::Escape($target)) { return $true }
  }
  foreach ($id in ($staticAllowedIds + (Load-DynamicAllowedIds))) {
    $normalizedId = Normalize-NotionId $id
    if ([string]::IsNullOrWhiteSpace($normalizedId)) { continue }
    if ($normalizedText -match [regex]::Escape($normalizedId)) { return $true }
  }
  return $false
}

$readOnlyPatterns = @(
  '(?i)(^|[_\.-])search\b',
  '(?i)(^|[_\.-])fetch\b',
  '(?i)(^|[_\.-])get[_\.-]?\w*\b',
  '(?i)(^|[_\.-])query[_\.-]?\w*\b'
)
foreach ($pattern in $readOnlyPatterns) {
  if ($toolText -match $pattern -and $toolText -notmatch '(?i)(create|update|move|duplicate|comment|delete|replace|append|apply_template|trash|share|permission)') {
    exit 0
  }
}

# These Notion writes stay approval-gated even when a known employment-page ID appears.
$blockedWritePatterns = @(
  '(?i)(^|[_\.-])move[_\.-]?',
  '(?i)(^|[_\.-])delete[_\.-]?',
  '(?i)(^|[_\.-])duplicate[_\.-]?',
  '(?i)(^|[_\.-])comment\b',
  '(?i)create[_\.-]?comment\b',
  '(?i)"in_trash"\s*:\s*true',
  '(?i)\bin_trash\b.*\btrue\b',
  '(?i)(share|permission|public_access|invite)'
)
foreach ($pattern in $blockedWritePatterns) {
  if ($toolText -match $pattern) {
    Write-Error "Notion write requires approval: blocked operation"
    exit 2
  }
}

$allowedWritePatterns = @(
  '(?i)create[_\.-]?pages?\b',
  '(?i)update[_\.-]?page\b',
  '(?i)create[_\.-]?database\b',
  '(?i)update[_\.-]?data[_\.-]?source\b',
  '(?i)create[_\.-]?view\b',
  '(?i)update[_\.-]?view\b',
  '(?i)replace[_\.-]?content\b',
  '(?i)update[_\.-]?content\b',
  '(?i)update[_\.-]?properties\b',
  '(?i)apply[_\.-]?template\b'
)
foreach ($pattern in $allowedWritePatterns) {
  if ($toolText -match $pattern) {
    if (Test-AllowedTarget $toolText) { exit 0 }
    Write-Error "Notion write requires approval: target is outside employment page allowlist"
    exit 2
  }
}

$genericWritePattern = '(?i)(create|update|move|duplicate|comment|delete|replace_content|update_content|apply_template|share|permission)'
if ($toolText -match $genericWritePattern) {
  Write-Error "Notion write requires approval: unrecognized write operation"
  exit 2
}

exit 0
