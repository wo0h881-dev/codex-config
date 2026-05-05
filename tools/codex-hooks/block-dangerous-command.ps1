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

  $hasAutomation = (
    $Text -match '(?i)web-novel-crawler-weekly-qa' -or
    $env:AUTOMATION_ID -eq 'web-novel-crawler-weekly-qa' -or
    $env:CODEX_AUTOMATION_ID -eq 'web-novel-crawler-weekly-qa' -or
    $env:AUTOMATION_NAME -eq 'Web Novel Crawler Weekly QA' -or
    $env:CODEX_AUTOMATION_NAME -eq 'Web Novel Crawler Weekly QA'
  )

  if (-not $hasAutomation) { return $false }

  return (Test-TextContainsPath $ContextText 'D:\Agent\Codex\web-novel-crawler')
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

if (Test-SecretReadTarget $commandText) {
  Write-Error '비밀 파일 읽기/검색 차단: .env, key/pem, token/secret/password/credential, auth.json 계열은 읽을 수 없습니다.'
  exit 2
}

if (Test-BasePythonDirectExecution $commandText) {
  Write-Error 'C base Python 직접 실행 차단: crawler 자동화는 D:\Agent\Codex\web-novel-crawler\.venv\Scripts\python.exe만 사용해야 합니다.'
  exit 2
}

if (Test-WebNovelCrawlerVenvPython $commandText) {
  if (Test-WebNovelCrawlerAutomationContext $commandText $contextText) {
    exit 0
  }
  Write-Error 'crawler venv Python 실행 범위 차단: web-novel-crawler-weekly-qa 자동화와 D:\Agent\Codex\web-novel-crawler cwd에서만 허용합니다.'
  exit 2
}

if (Test-WebNovelCrawlerRuntimePython $commandText) {
  if (Test-WebNovelCrawlerAutomationContext $commandText $contextText) {
    exit 0
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
