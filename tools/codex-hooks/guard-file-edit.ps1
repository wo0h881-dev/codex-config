param()

$ErrorActionPreference = 'SilentlyContinue'

$WorkspaceRoot = 'D:\Agent\Codex'

function Get-HookPayload {
  $inputText = [Console]::In.ReadToEnd()
  if ([string]::IsNullOrWhiteSpace($inputText)) { return [pscustomobject]@{ Raw = ''; Json = $null } }
  try {
    return [pscustomobject]@{ Raw = $inputText; Json = ($inputText | ConvertFrom-Json) }
  } catch {
    return [pscustomobject]@{ Raw = $inputText; Json = $null }
  }
}

function Add-StringValue {
  param([System.Collections.Generic.List[string]]$List, [object]$Value)
  if ($null -eq $Value) { return }
  if ($Value -is [string] -and -not [string]::IsNullOrWhiteSpace($Value)) { [void]$List.Add($Value) }
}

function Collect-PathLikeStrings {
  param([object]$Value, [System.Collections.Generic.List[string]]$List)
  if ($null -eq $Value) { return }
  if ($Value -is [System.Collections.IDictionary]) {
    foreach ($k in $Value.Keys) {
      if ([string]$k -match '(?i)^(file|path|target|cwd|workdir|filename|uri)$') { Collect-PathLikeStrings $Value[$k] $List }
    }
    return
  }
  if ($Value -is [System.Collections.IEnumerable] -and -not ($Value -is [string])) {
    foreach ($item in $Value) { Collect-PathLikeStrings $item $List }
    return
  }
  if ($Value -is [string]) { Add-StringValue $List $Value; return }
  foreach ($prop in $Value.PSObject.Properties) {
    if ($prop.Name -match '(?i)^(file|path|target|cwd|workdir|filename|uri)$') {
      Collect-PathLikeStrings $prop.Value $List
    }
  }
}

function Get-NormalizedPath {
  param([string]$Text)
  if ([string]::IsNullOrWhiteSpace($Text)) { return $null }
  try {
    if ([System.IO.Path]::IsPathRooted($Text)) {
      return [System.IO.Path]::GetFullPath($Text)
    }
    return [System.IO.Path]::GetFullPath((Join-Path $WorkspaceRoot $Text))
  } catch {
    return $Text
  }
}

function Test-InWorkspace {
  param([string]$Path)
  $root = [System.IO.Path]::GetFullPath($WorkspaceRoot).TrimEnd('\')
  $target = [System.IO.Path]::GetFullPath($Path).TrimEnd('\')
  return ($target -ieq $root -or $target.StartsWith($root + '\', [System.StringComparison]::OrdinalIgnoreCase))
}

function Test-ProtectedPath {
  param([string]$Text)
  if ([string]::IsNullOrWhiteSpace($Text)) { return $false }
  $normalized = ($Text -replace '\\','/').ToLowerInvariant()
  $patterns = @(
    '(^|/)\.git(/|$)',
    '(^|/)\.codex(/|$)',
    '(^|/)config(/|$)',
    '(^|/)\.env([^/]*$|/)',
    '\.pem$',
    '\.key$',
    '(^|/)[^/]*(token|secret)[^/]*$',
    '(^|/)auth\.json$',
    '(^|/)hooks\.json$',
    '(^|/)config\.toml$'
  )
  foreach ($pattern in $patterns) {
    if ($normalized -match $pattern) { return $true }
  }
  return $false
}

$payload = Get-HookPayload
$candidates = [System.Collections.Generic.List[string]]::new()
@($env:FILE, $env:file, $env:CODEX_FILE, $env:CODEX_PATH) | ForEach-Object { Add-StringValue $candidates $_ }
Collect-PathLikeStrings $payload.Json $candidates

foreach ($candidate in $candidates) {
  $path = Get-NormalizedPath $candidate
  if ([string]::IsNullOrWhiteSpace($path)) { continue }
  if (-not (Test-InWorkspace $path)) {
    Write-Error "작업공간 밖 파일 수정 차단: $path"
    exit 2
  }
  if (Test-ProtectedPath $path) {
    Write-Error "보호된 파일/폴더 수정 차단: $path"
    exit 2
  }
}

exit 0
