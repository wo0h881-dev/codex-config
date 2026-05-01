param()

$ErrorActionPreference = 'SilentlyContinue'

$inputText = [Console]::In.ReadToEnd()
$summary = $inputText
if ([string]::IsNullOrWhiteSpace($summary)) { $summary = 'Notion 승인 요청' }
if ($summary.Length -gt 500) { $summary = $summary.Substring(0, 500) + '...' }

Write-Output "Notion 쓰기 승인 요청 확인: $summary"
exit 0
