param()

$ErrorActionPreference = 'SilentlyContinue'

function Get-HookPayload {
  $inputText = [Console]::In.ReadToEnd()
  if ([string]::IsNullOrWhiteSpace($inputText)) { return [pscustomobject]@{ Raw = ''; Json = $null } }
  try {
    return [pscustomobject]@{ Raw = $inputText; Json = ($inputText | ConvertFrom-Json) }
  } catch {
    return [pscustomobject]@{ Raw = $inputText; Json = $null }
  }
}

function Get-DeepText {
  param([object]$Value)
  if ($null -eq $Value) { return '' }
  if ($Value -is [string]) { return $Value }
  try { return ($Value | ConvertTo-Json -Depth 100 -Compress) } catch { return [string]$Value }
}

function Get-CommandText {
  param([object]$Payload)
  $textParts = @(
    $env:COMMAND,
    $env:command,
    $env:CODEX_COMMAND,
    $env:CWD,
    $env:cwd,
    $env:CODEX_CWD,
    $env:AUTOMATION_ID,
    $env:automation_id,
    $env:CODEX_AUTOMATION_ID,
    $env:AUTOMATION_NAME,
    $env:automation_name,
    $env:CODEX_AUTOMATION_NAME,
    $Payload.Raw,
    (Get-DeepText $Payload.Json)
  ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
  return ($textParts -join "`n")
}

function Test-TextContainsPath {
  param([string]$Text, [string]$Path)
  if ([string]::IsNullOrWhiteSpace($Text) -or [string]::IsNullOrWhiteSpace($Path)) { return $false }
  $normalizedText = (($Text -replace '\\','/') -replace '/+','/').ToLowerInvariant()
  $normalizedPath = (($Path -replace '\\','/') -replace '/+','/').ToLowerInvariant()
  return $normalizedText.Contains($normalizedPath)
}

function Get-NormalizedPath {
  param([string]$Path)
  if ([string]::IsNullOrWhiteSpace($Path)) { return '' }
  return (([System.IO.Path]::GetFullPath($Path) -replace '\\','/') -replace '/+','/').ToLowerInvariant()
}

function Test-PathWithin {
  param([string]$Path, [string]$Root)
  $normalizedPath = Get-NormalizedPath $Path
  $normalizedRoot = Get-NormalizedPath $Root
  if ([string]::IsNullOrWhiteSpace($normalizedPath) -or [string]::IsNullOrWhiteSpace($normalizedRoot)) { return $false }
  return $normalizedPath.StartsWith($normalizedRoot.TrimEnd('/') + '/')
}

function Get-ExecutionContextText {
  param([object]$Payload)
  $parts = @(
    $env:CWD,
    $env:cwd,
    $env:CODEX_CWD,
    $env:WORKDIR,
    $env:workdir,
    $env:CODEX_WORKDIR
  )

  if ($null -ne $Payload.Json) {
    foreach ($name in @('cwd', 'CWD', 'workdir', 'WORKDIR', 'working_directory', 'workingDirectory')) {
      try {
        $value = $Payload.Json.$name
        if ($value -is [string] -and -not [string]::IsNullOrWhiteSpace($value)) {
          $parts += $value
        }
      } catch {}
    }
  }

  return (($parts | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }) -join "`n")
}

function Test-WebNovelCrawlerAutomationContext {
  param([string]$Text, [string]$ContextText)
  if ([string]::IsNullOrWhiteSpace($Text)) { return $false }

  $hasAutomation = Test-WebNovelAutomationId $Text

  if (-not $hasAutomation) { return $false }

  return (Test-TextContainsPath $ContextText 'D:\Agent\Codex\web-novel-crawler')
}

function Test-WebNovelAutomationId {
  param([string]$Text)
  return (
    $Text -match '(?i)web-novel-crawler-weekly-qa' -or
    $env:AUTOMATION_ID -eq 'web-novel-crawler-weekly-qa' -or
    $env:CODEX_AUTOMATION_ID -eq 'web-novel-crawler-weekly-qa' -or
    $env:AUTOMATION_NAME -eq 'Web Novel Crawler Weekly QA' -or
    $env:CODEX_AUTOMATION_NAME -eq 'Web Novel Crawler Weekly QA' -or
    $env:AUTOMATION_NAME -eq 'Crawler + Lovable QA Auto Deploy' -or
    $env:CODEX_AUTOMATION_NAME -eq 'Crawler + Lovable QA Auto Deploy'
  )
}

function Test-WebNovelLovableAutomationContext {
  param([string]$Text, [string]$ContextText)
  if ([string]::IsNullOrWhiteSpace($Text)) { return $false }
  if (-not (Test-WebNovelAutomationId $Text)) { return $false }
  return (Test-TextContainsPath $ContextText 'D:\Agent\Codex\Lovable_Dashboard')
}

function Test-WebNovelAutomationRepoContext {
  param([string]$Text, [string]$ContextText)
  if (-not (Test-WebNovelAutomationId $Text)) { return $false }
  return (
    (Test-TextContainsPath $ContextText 'D:\Agent\Codex\web-novel-crawler') -or
    (Test-TextContainsPath $ContextText 'D:\Agent\Codex\Lovable_Dashboard') -or
    (Test-TextContainsPath $ContextText 'D:\Agent\Codex')
  )
}

function Test-WebNovelCrawlerVenvPython {
  param([string]$Text)
  return (Test-TextContainsPath $Text 'D:\Agent\Codex\web-novel-crawler\.venv\Scripts\python.exe')
}

function Test-WebNovelCrawlerRuntimePython {
  param([string]$Text)
  return (Test-TextContainsPath $Text 'D:\Agent\Codex\runtime\python\python.exe')
}

function Test-BasePythonDirectExecution {
  param([string]$Text)
  return (Test-TextContainsPath $Text 'C:\Users\suna\AppData\Local\Python\pythoncore-3.14-64\python.exe')
}

function Test-WindowsAppsPythonAlias {
  param([string]$Text)
  if ([string]::IsNullOrWhiteSpace($Text)) { return $false }

  return (
    $Text -match "(?i)(^|\s|[""'])python(\.exe)?(\s|[""']|$)" -or
    (Test-TextContainsPath $Text 'C:\Users\suna\AppData\Local\Microsoft\WindowsApps\python.exe')
  )
}

function Get-FirstPathFromText {
  param([string]$Text)
  if ([string]::IsNullOrWhiteSpace($Text)) { return $null }

  $pathPatterns = @(
    '(?i)[a-z]:\\[^\r\n"''|;]+',
    '(?i)[a-z]:/[^\r\n"''|;]+'
  )

  foreach ($pattern in $pathPatterns) {
    $match = [regex]::Match($Text, $pattern)
    if ($match.Success) { return $match.Value.Trim() }
  }

  return $null
}

function Test-AllowedCrawlerReadPath {
  param([string]$Path)
  if ([string]::IsNullOrWhiteSpace($Path)) { return $false }

  $resolved = Get-NormalizedPath $Path
  $exactAllow = @(
    'D:\Agent\Codex\webnovel-ops\watchlist.md',
    'D:\Agent\Codex\webnovel-ops\field-contract.md',
    'D:\Agent\Codex\webnovel-ops\run-log.md',
    'D:\Agent\Codex\web-novel-crawler\requirements.txt',
    'D:\Agent\Codex\web-novel-crawler\.venv\pyvenv.cfg',
    'D:\Agent\Codex\web-novel-crawler\.github\workflows\main.yml'
  ) | ForEach-Object { Get-NormalizedPath $_ }

  if ($exactAllow -contains $resolved) { return $true }
  if (Test-PathWithin $Path 'D:\Agent\Codex\web-novel-crawler') { return $true }

  return $false
}

function Test-AllowedCrawlerReadCommand {
  param([string]$Text, [string]$ContextText)
  if (-not (Test-WebNovelCrawlerAutomationContext $Text $ContextText)) { return $false }
  if ($Text -notmatch '(?i)^\s*(Get-Content|gc|cat|type|Get-ChildItem|gci|dir|ls|Select-String|sls|findstr|Test-Path|Get-Item|gi)\b') { return $false }

  $firstPath = Get-FirstPathFromText $Text
  if ($null -eq $firstPath) { return $false }
  return (Test-AllowedCrawlerReadPath $firstPath)
}

function Test-AllowedCrawlerPyCompileCommand {
  param([string]$Text, [string]$ContextText)
  if (-not (Test-WebNovelCrawlerAutomationContext $Text $ContextText)) { return $false }
  if (-not (Test-WebNovelCrawlerVenvPython $Text)) { return $false }
  return ($Text -match '(?i)-m\s+py_compile\s+main\.py\s+naver\.py\s+ridi\.py')
}

function Test-AllowedCrawlerMainRunCommand {
  param([string]$Text, [string]$ContextText)
  if (-not (Test-WebNovelCrawlerAutomationContext $Text $ContextText)) { return $false }
  if (-not (Test-WebNovelCrawlerVenvPython $Text)) { return $false }
  return ($Text -match '(?i)(^|\s)main\.py(\s|$)')
}

function Test-AllowedCrawlerRunLogAppend {
  param([string]$Text, [string]$ContextText)
  if (-not (Test-WebNovelAutomationRepoContext $Text $ContextText)) { return $false }
  if ($Text -notmatch '(?i)(^|\s|;)Add-Content\b') { return $false }
  if (-not (Test-TextContainsPath $Text 'D:\Agent\Codex\webnovel-ops\run-log.md')) { return $false }
  if ($Text -match '(?i)\b(WEBAPP_URL|\.env|token|secret|credential|password|auth\.json|key|pem)\b') { return $false }
  return $true
}

function Test-AllowedLovableReadPath {
  param([string]$Path)
  if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
  if (Test-PathWithin $Path 'D:\Agent\Codex\Lovable_Dashboard') { return $true }
  return $false
}

function Test-AllowedLovableReadCommand {
  param([string]$Text, [string]$ContextText)
  if (-not (Test-WebNovelLovableAutomationContext $Text $ContextText)) { return $false }
  if ($Text -notmatch '(?i)^\s*(Get-Content|gc|cat|type|Get-ChildItem|gci|dir|ls|Select-String|sls|findstr|Test-Path|Get-Item|gi)\b') { return $false }

  $firstPath = Get-FirstPathFromText $Text
  if ($null -eq $firstPath) { return $true }
  return (Test-AllowedLovableReadPath $firstPath)
}

function Test-AllowedLovableNpmCommand {
  param([string]$Text, [string]$ContextText)
  if (-not (Test-WebNovelLovableAutomationContext $Text $ContextText)) { return $false }
  return ($Text -match '(?i)^\s*npm(\.cmd)?\s+run\s+(test|build)\b')
}

function Test-AllowedAutomationGitCommand {
  param([string]$Text, [string]$ContextText)
  if (-not (Test-WebNovelAutomationRepoContext $Text $ContextText)) { return $false }
  if ($Text -match '(?i)\s(--force|-f)\b') { return $false }
  if ($Text -match '(?i)\b(reset|rebase|clean|restore)\b') { return $false }
  return ($Text -match '(?i)^\s*git\s+(status|diff|show|log|branch|rev-parse|switch|merge|add|commit|push)\b')
}

function Test-WebAppUrlReference {
  param([string]$Text)
  if ([string]::IsNullOrWhiteSpace($Text)) { return $false }
  return ($Text -match '(?i)WEBAPP_URL')
}

function Test-AllowedWebAppUrlExistenceCheck {
  param([string]$Text, [string]$ContextText)
  if (-not (Test-WebNovelCrawlerAutomationContext $Text $ContextText)) { return $false }
  if ($Text -notmatch '(?i)\bTest-Path\s+Env:WEBAPP_URL\b') { return $false }
  if ($Text -match '(?i)\b(Write-Output|Write-Host|echo|Out-File|Set-Content|Add-Content|Get-Item|Get-ChildItem)\b') { return $false }
  return $true
}

function Test-SecretReadTarget {
  param([string]$Text)
  if ([string]::IsNullOrWhiteSpace($Text)) { return $false }

  $normalized = ($Text -replace '\\','/').ToLowerInvariant()
  $secretPatterns = @(
    '(^|[\s"''=:/])\.env($|[\s"'';/])',
    '(^|[\s"''=:/])\.env\.[^\s"'';|]+',
    '(^|/)[^/\s"'';|]*(token|secret|credential|password|passwd|apikey|api-key)[^/\s"'';|]*($|[\s"'';|])',
    '(^|/)(auth|credentials)\.json($|[\s"'';|])',
    '\.(pem|key|p12|pfx|crt)($|[\s"'';|])',
    'id_rsa($|[\s"'';|])',
    'id_ed25519($|[\s"'';|])'
  )

  foreach ($pattern in $secretPatterns) {
    if ($normalized -match $pattern) { return $true }
  }
  return $false
}

function Test-ReadOnlyCommand {
  param([string]$Text)
  if ([string]::IsNullOrWhiteSpace($Text)) { return $true }

  $normalized = $Text.Trim()

  $mutatingPatterns = @(
    '(?i)(^|\s|;)Set-Content\b',
    '(?i)(^|\s|;)Add-Content\b',
    '(?i)(^|\s|;)Out-File\b',
    '(?i)(^|\s|;)New-Item\b',
    '(?i)(^|\s|;)Remove-Item\b',
    '(?i)(^|\s|;)Move-Item\b',
    '(?i)(^|\s|;)Copy-Item\b',
    '(?i)(^|\s|;)Rename-Item\b',
    '(?i)(^|\s|;)Set-Item\b',
    '(?i)(^|\s|;)Clear-Item\b',
    '(?i)(^|\s|;)git\s+(add|commit|push|pull|fetch|merge|rebase|reset|checkout|switch|restore|clean)\b',
    '(?i)(^|\s|;)(curl|wget|Invoke-WebRequest|Invoke-RestMethod|iwr|irm)\b',
    '(?i)(^|\s|;)(npm|pnpm|yarn|pip|uv|cargo|go)\s+(install|add|update|publish|deploy|run)\b',
    '(?i)(^|\s|;)(powershell|pwsh|cmd|bash|sh|python|node)\b',
    '(?i)\s(--force|-f)\b',
    '(?i)\s>\s|\s>>\s'
  )
  foreach ($pattern in $mutatingPatterns) {
    if ($normalized -match $pattern) { return $false }
  }

  $readOnlyPattern = '(?i)^\s*(Get-ChildItem|gci|dir|ls|Get-Content|gc|cat|type|Select-String|sls|findstr|git\s+(status|diff|show|log|branch|rev-parse)|Test-Path|Get-Item|gi|Get-Location|pwd|Measure-Object|Where-Object|Select-Object|Sort-Object|Format-Table|Format-List)\b'
  $segments = $normalized -split '[|;]'
  foreach ($segment in $segments) {
    $s = $segment.Trim()
    if ([string]::IsNullOrWhiteSpace($s)) { continue }
    if ($s -notmatch $readOnlyPattern) { return $false }
  }

  return $true
}

$payload = Get-HookPayload
$commandText = Get-CommandText $payload
$contextText = Get-ExecutionContextText $payload

if (Test-WebAppUrlReference $commandText) {
  if (Test-AllowedWebAppUrlExistenceCheck $commandText $contextText) {
    exit 0
  }
  Write-Error 'WEBAPP_URL 값 출력/저장 차단: 존재 여부 확인만 허용합니다.'
  exit 2
}

if (Test-SecretReadTarget $commandText) {
  Write-Error '비밀 파일 읽기/검색 차단: .env, key/pem, token/secret/password/credential, auth.json 계열은 읽을 수 없습니다.'
  exit 2
}

if (Test-BasePythonDirectExecution $commandText) {
  Write-Error 'C base Python 직접 실행 차단: crawler 자동화는 D:\Agent\Codex\web-novel-crawler\.venv\Scripts\python.exe만 사용해야 합니다.'
  exit 2
}

if (Test-WindowsAppsPythonAlias $commandText) {
  Write-Error 'WindowsApps Python alias 실행 차단: crawler 자동화는 프로젝트 venv Python만 사용해야 합니다.'
  exit 2
}

if (Test-AllowedCrawlerReadCommand $commandText $contextText) {
  exit 0
}

if (Test-AllowedLovableReadCommand $commandText $contextText) {
  exit 0
}

if (Test-AllowedCrawlerPyCompileCommand $commandText $contextText) {
  exit 0
}

if (Test-AllowedCrawlerMainRunCommand $commandText $contextText) {
  exit 0
}

if (Test-AllowedLovableNpmCommand $commandText $contextText) {
  exit 0
}

if (Test-AllowedCrawlerRunLogAppend $commandText $contextText) {
  exit 0
}

if (Test-AllowedAutomationGitCommand $commandText $contextText) {
  exit 0
}

if (Test-WebNovelCrawlerVenvPython $commandText) {
  if (Test-WebNovelCrawlerAutomationContext $commandText $contextText) {
    Write-Error 'crawler venv Python 실행 범위 차단: read, py_compile, main.py 실행만 허용합니다.'
    exit 2
  }
  Write-Error 'crawler venv Python 실행 범위 차단: web-novel-crawler-weekly-qa 자동화와 D:\Agent\Codex\web-novel-crawler cwd에서만 허용합니다.'
  exit 2
}

if (Test-WebNovelCrawlerRuntimePython $commandText) {
  if (Test-WebNovelCrawlerAutomationContext $commandText $contextText) {
    Write-Error 'crawler runtime Python 직접 실행 차단: 프로젝트 venv Python만 허용합니다.'
    exit 2
  }
  Write-Error 'crawler runtime Python 실행 범위 차단: web-novel-crawler-weekly-qa 자동화와 D:\Agent\Codex\web-novel-crawler cwd에서만 허용합니다.'
  exit 2
}

if (Test-ReadOnlyCommand $commandText) {
  exit 0
}

$blockedPatterns = @(
  '(?i)\brm\s+(-[^\r\n;|&]*[rR][^\r\n;|&]*[fF]|-[^\r\n;|&]*[fF][^\r\n;|&]*[rR])\b',
  '(?i)\bRemove-Item\b(?=[^\r\n;|&]*\b-Recurse\b)(?=[^\r\n;|&]*\b-Force\b)',
  '(?i)\brmdir\s+/s\b',
  '(?i)\bdel\s+/s\b',
  '(?i)\bdrop\s+table\b',
  '(?i)\bgit\s+push\b[^\r\n]*\s--force(?:\b|=)',
  '(?i)\bgit\s+push\b[^\r\n]*\s-f(?:\s|$)',
  '(?i)\bformat\s+[a-z]:',
  '(?i)\bdiskpart\b',
  '(?i)\bSet-ExecutionPolicy\b\s+Unrestricted\b',
  '(?i)\bInvoke-WebRequest\b|\bInvoke-RestMethod\b|\biwr\b|\birm\b|\bcurl\b|\bwget\b',
  '(?i)\bMove-Item\b|\bRename-Item\b',
  '(?i)\bRemove-Item\b|\brm\b|\bdel\b|\brmdir\b'
)

foreach ($pattern in $blockedPatterns) {
  if ($commandText -match $pattern) {
    Write-Error "위험/변경 가능 명령 차단: $($Matches[0])"
    exit 2
  }
}

exit 0
