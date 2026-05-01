param()

$ErrorActionPreference = 'SilentlyContinue'

$inputText = [Console]::In.ReadToEnd()
$payload = $null
if (-not [string]::IsNullOrWhiteSpace($inputText)) {
  try { $payload = $inputText | ConvertFrom-Json } catch { $payload = $null }
}

$summary = $env:FILE
if ([string]::IsNullOrWhiteSpace($summary)) { $summary = $env:CODEX_FILE }
if ([string]::IsNullOrWhiteSpace($summary) -and $payload) {
  $json = $payload | ConvertTo-Json -Depth 20 -Compress
  $paths = [regex]::Matches($json, '([A-Za-z]:\\[^"'']+|/[^"'']+)') | Select-Object -First 5 | ForEach-Object { $_.Value }
  if ($paths) { $summary = ($paths -join ', ') }
}
if ([string]::IsNullOrWhiteSpace($summary)) { $summary = '파일 수정 도구 실행됨' }

$message = "수정됨: $summary"
Write-Output $message

$logDir = 'D:\Agent\Codex\logs'
if (-not (Test-Path -LiteralPath $logDir)) {
  New-Item -ItemType Directory -Force -Path $logDir | Out-Null
}
$line = "{0}`t{1}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $message
Add-Content -LiteralPath (Join-Path $logDir 'hook-file-edits.log') -Value $line -Encoding UTF8

exit 0
