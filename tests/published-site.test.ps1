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
  'nadwa\\index.html',
  'nocturne\\index.html',
  'roastery\\index.html',
  'majlis\\index.html',
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
Assert-Contains $entry 'High-end Arabic tableware' 'tableware sector'
Assert-Contains $entry 'Fine fragrance' 'fragrance sector'
Assert-Contains $entry 'Specialty coffee' 'coffee sector'
Assert-Contains $entry 'Restaurant' 'restaurant sector'
Assert-NotContains $entry 'hwl1117.github.io/kemari-sample-audit' 'legacy project link'

$nadwa = Get-Content -Raw (Join-Path $siteRoot 'nadwa\\index.html')
Assert-Contains $nadwa 'Corporate and wedding gifting' 'tableware gifting route'
Assert-Contains $nadwa 'Build a table' 'tableware merchandising action'

$nocturne = Get-Content -Raw (Join-Path $siteRoot 'nocturne\\index.html')
Assert-Contains $nocturne 'Find your scent' 'fragrance discovery route'
Assert-Contains $nocturne 'Discovery set' 'fragrance sample route'

$roastery = Get-Content -Raw (Join-Path $siteRoot 'roastery\\index.html')
Assert-Contains $roastery 'Choose your roast profile' 'coffee selection route'
Assert-Contains $roastery 'Wholesale coffee' 'coffee wholesale route'

$majlis = Get-Content -Raw (Join-Path $siteRoot 'majlis\\index.html')
Assert-Contains $majlis 'Reserve a table' 'restaurant reservation route'
Assert-Contains $majlis 'Private dining' 'restaurant events route'

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

$workflow = Get-ChildItem -Path (Split-Path -Parent $siteRoot) -File -Filter '41-*.md' | Select-Object -First 1
if (-not $workflow) {
  throw 'Missing four-sector WhatsApp workflow.'
}

$workflowText = Get-Content -Raw $workflow.FullName
Assert-Contains $workflowText 'WhatsApp Business' 'WhatsApp channel policy'
Assert-Contains $workflowText 'one first-touch channel' 'channel deduplication policy'
Assert-Contains $workflowText 'explicit approval' 'outbound approval policy'

Write-Host "Published-site checks passed for $($requiredFiles.Count) pages."
