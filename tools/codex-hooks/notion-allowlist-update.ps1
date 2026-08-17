param()

$ErrorActionPreference = 'SilentlyContinue'

$EmploymentRootId = '34c11b6c-2a63-80f0-bbec-c72bfe773f70'
$AllowlistPath = Join-Path $PSScriptRoot 'notion-allowlist.json'
$KnownEmploymentChildren = @(
  '35111b6c2a6380f4bfe8e3c50731ee45',
  '35111b6c2a638082a59f000b86242e28',
  '8575be5ac396407f8e3b1c2338ea60c4',
  '12f48c1e9fb7437ba7174ec89dda8d71'
)

function Normalize-NotionId {
  param([string]$Value)
  if ([string]::IsNullOrWhiteSpace($Value)) { return '' }
  return ($Value -replace '[^0-9a-fA-F]', '').ToLowerInvariant()
}

function Load-Allowlist {
  if (-not (Test-Path -LiteralPath $AllowlistPath)) { return @() }
  try {
    $raw = Get-Content -LiteralPath $AllowlistPath -Raw
    if ([string]::IsNullOrWhiteSpace($raw)) { return @() }
    $obj = $raw | ConvertFrom-Json
    if ($obj -and $obj.ids) { return @($obj.ids) }
  } catch {}
  return @()
}

function Save-Allowlist {
  param([string[]]$Ids)
  try {
    $payload = [pscustomobject]@{ ids = $Ids }
    $json = $payload | ConvertTo-Json -Depth 3
    Set-Content -LiteralPath $AllowlistPath -Value $json -Encoding UTF8
  } catch {}
}

$inputText = [Console]::In.ReadToEnd()
if ([string]::IsNullOrWhiteSpace($inputText)) { exit 0 }

$normalizedInput = Normalize-NotionId $inputText
$normalizedEmployment = Normalize-NotionId $EmploymentRootId
$knownScopeMatched = $normalizedInput -match [regex]::Escape($normalizedEmployment)
foreach ($id in $KnownEmploymentChildren) {
  if ($normalizedInput -match [regex]::Escape((Normalize-NotionId $id))) {
    $knownScopeMatched = $true
    break
  }
}
if (-not $knownScopeMatched) {
  exit 0
}

$existing = Load-Allowlist | ForEach-Object { Normalize-NotionId $_ } | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
$set = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($id in $existing) { [void]$set.Add($id) }

[void]$set.Add($normalizedEmployment)

# Seed known databases currently under the employment page.
foreach ($id in $KnownEmploymentChildren) { [void]$set.Add((Normalize-NotionId $id)) }

# Collect page, database, data source, and view IDs from Notion fetch/search output.
foreach ($m in ([regex]::Matches($inputText, '(?i)[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}'))) {
  [void]$set.Add((Normalize-NotionId $m.Value))
}
foreach ($m in ([regex]::Matches($inputText, '(?i)\b[0-9a-f]{32}\b'))) {
  [void]$set.Add((Normalize-NotionId $m.Value))
}
foreach ($m in ([regex]::Matches($inputText, '(?i)collection://([0-9a-f-]{32,36})'))) {
  [void]$set.Add((Normalize-NotionId $m.Groups[1].Value))
}
foreach ($m in ([regex]::Matches($inputText, '(?i)view://([0-9a-f-]{32,36})'))) {
  [void]$set.Add((Normalize-NotionId $m.Groups[1].Value))
}

$final = $set.ToArray() | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object
Save-Allowlist $final
exit 0
