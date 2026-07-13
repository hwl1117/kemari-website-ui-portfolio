$ErrorActionPreference = 'Stop'

$siteRoot = Split-Path -Parent $PSScriptRoot

function Assert-Contains {
  param([string]$Content, [string]$Needle, [string]$Label)

  if ($Content -notmatch [regex]::Escape($Needle)) {
    throw "Missing ${Label}: $Needle"
  }
}

function Assert-NotContains {
  param([string]$Content, [string]$Needle, [string]$Label)

  if ($Content -match [regex]::Escape($Needle)) {
    throw "Unexpected ${Label}: $Needle"
  }
}

$requiredFiles = @(
  'index.html',
  'nocturne\\index.html',
  'signal\\index.html',
  'kinfolk\\index.html',
  'ui-audit\\index.html'
)

foreach ($relativePath in $requiredFiles) {
  $path = Join-Path $siteRoot $relativePath
  if (-not (Test-Path $path)) {
    throw "Missing public-site page: $relativePath"
  }
}

$entry = Get-Content -Raw (Join-Path $siteRoot 'index.html')
Assert-Contains $entry 'Kemari Blakemore | Website UI Directions' 'portfolio title'
Assert-Contains $entry './ui-audit/' 'root-relative UI audit route'
Assert-NotContains $entry 'hwl1117.github.io/kemari-sample-audit' 'legacy project link'

$audit = Get-Content -Raw (Join-Path $siteRoot 'ui-audit\\index.html')
Assert-Contains $audit 'Website UI Audit | Kemari Blakemore' 'audit title'
Assert-Contains $audit 'href="../"' 'return route to portfolio root'
Assert-NotContains $audit '../portfolio/' 'source-only portfolio path'

$allHtml = Get-ChildItem -Path $siteRoot -Recurse -File -Filter '*.html'
foreach ($file in $allHtml) {
  Assert-NotContains (Get-Content -Raw $file.FullName) 'hwl1117.github.io/kemari-sample-audit' "legacy project link in $($file.Name)"
}

$pngs = Get-ChildItem -Path $siteRoot -Recurse -File -Filter '*.png'
if ($pngs) {
  throw "The public package must exclude unreferenced PNG source assets: $($pngs.Name -join ', ')"
}

$webpAssets = Get-ChildItem -Path (Join-Path $siteRoot 'assets') -File -Filter '*.webp'
if ($webpAssets.Count -lt 6) {
  throw 'The public package is missing optimized WebP assets.'
}

foreach ($asset in $webpAssets) {
  if ($asset.Length -gt 500KB) {
    throw "Published WebP asset exceeds 500 KiB: $($asset.Name)"
  }
}

Write-Host "Published-site checks passed for $($requiredFiles.Count) pages."
