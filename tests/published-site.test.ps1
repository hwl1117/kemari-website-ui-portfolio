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

function Assert-UniqueImageSources {
  param([string]$Content, [string]$Label)

  $sources = [regex]::Matches($Content, '<img\b[^>]*\bsrc="([^"]+)"') | ForEach-Object { $_.Groups[1].Value }
  if ($sources.Count -lt 7) {
    throw "${Label} must include seven image placements."
  }

  if (($sources | Select-Object -Unique).Count -ne $sources.Count) {
    throw "${Label} repeats a material image instead of using distinct artwork."
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
Assert-Contains $entry 'Private case studies are shared individually.' 'private case-study positioning'
Assert-NotContains $entry 'High-end Arabic tableware' 'tableware sector on public root'
Assert-NotContains $entry 'Fine fragrance' 'fragrance sector on public root'
Assert-NotContains $entry 'Specialty coffee' 'coffee sector on public root'
Assert-NotContains $entry 'Restaurant' 'restaurant sector on public root'
Assert-NotContains $entry './nadwa/' 'tableware case link on public root'
Assert-NotContains $entry './nocturne/' 'fragrance case link on public root'
Assert-NotContains $entry './roastery/' 'coffee case link on public root'
Assert-NotContains $entry './majlis/' 'restaurant case link on public root'
Assert-NotContains $entry 'hwl1117.github.io/kemari-sample-audit' 'legacy project link'

$nadwa = Get-Content -Raw (Join-Path $siteRoot 'nadwa\\index.html')
Assert-Contains $nadwa 'Corporate and wedding gifting' 'tableware gifting route'
Assert-Contains $nadwa 'Build a table' 'tableware merchandising action'
Assert-NotContains $nadwa 'href="../"' 'tableware route back to overview'
Assert-Contains $nadwa 'case-rail' 'tableware editorial rail'
Assert-Contains $nadwa 'editorial-grid' 'tableware grid layout'
Assert-Contains $nadwa 'nadwa-graded.webp' 'tableware graded image'
Assert-Contains $nadwa 'reference-hero' 'tableware reference hero composition'
Assert-Contains $nadwa 'brand-feature' 'tableware reference brand composition'
Assert-Contains $nadwa 'category-showcase' 'tableware reference case composition'
Assert-Contains $nadwa 'service-canvas' 'tableware reference service composition'
Assert-Contains $nadwa 'micro-footer' 'tableware reference footer composition'
Assert-Contains $nadwa 'nadwa-detail-graded.webp' 'tableware graded detail image'
Assert-UniqueImageSources $nadwa 'tableware case'

$nocturne = Get-Content -Raw (Join-Path $siteRoot 'nocturne\\index.html')
Assert-Contains $nocturne 'Find your scent' 'fragrance discovery route'
Assert-Contains $nocturne 'Discovery set' 'fragrance sample route'
Assert-NotContains $nocturne 'href="../"' 'fragrance route back to overview'
Assert-Contains $nocturne 'case-rail' 'fragrance editorial rail'
Assert-Contains $nocturne 'editorial-grid' 'fragrance grid layout'
Assert-Contains $nocturne 'nocturne-graded.webp' 'fragrance graded image'
Assert-Contains $nocturne 'reference-hero' 'fragrance reference hero composition'
Assert-Contains $nocturne 'brand-feature' 'fragrance reference brand composition'
Assert-Contains $nocturne 'category-showcase' 'fragrance reference case composition'
Assert-Contains $nocturne 'service-canvas' 'fragrance reference service composition'
Assert-Contains $nocturne 'micro-footer' 'fragrance reference footer composition'
Assert-Contains $nocturne 'nocturne-detail-graded.webp' 'fragrance graded detail image'
Assert-UniqueImageSources $nocturne 'fragrance case'

$roastery = Get-Content -Raw (Join-Path $siteRoot 'roastery\\index.html')
Assert-Contains $roastery 'Choose your roast profile' 'coffee selection route'
Assert-Contains $roastery 'Wholesale coffee' 'coffee wholesale route'
Assert-NotContains $roastery 'href="../"' 'coffee route back to overview'
Assert-Contains $roastery 'case-rail' 'coffee editorial rail'
Assert-Contains $roastery 'editorial-grid' 'coffee grid layout'
Assert-Contains $roastery 'roastery-graded.webp' 'coffee graded image'
Assert-Contains $roastery 'reference-hero' 'coffee reference hero composition'
Assert-Contains $roastery 'brand-feature' 'coffee reference brand composition'
Assert-Contains $roastery 'category-showcase' 'coffee reference case composition'
Assert-Contains $roastery 'service-canvas' 'coffee reference service composition'
Assert-Contains $roastery 'micro-footer' 'coffee reference footer composition'
Assert-Contains $roastery 'roastery-detail-graded.webp' 'coffee graded detail image'
Assert-UniqueImageSources $roastery 'coffee case'

$majlis = Get-Content -Raw (Join-Path $siteRoot 'majlis\\index.html')
Assert-Contains $majlis 'Reserve a table' 'restaurant reservation route'
Assert-Contains $majlis 'Private dining' 'restaurant events route'
Assert-NotContains $majlis 'href="../"' 'restaurant route back to overview'
Assert-Contains $majlis 'case-rail' 'restaurant editorial rail'
Assert-Contains $majlis 'editorial-grid' 'restaurant grid layout'
Assert-Contains $majlis 'majlis-graded.webp' 'restaurant graded image'
Assert-Contains $majlis 'reference-hero' 'restaurant reference hero composition'
Assert-Contains $majlis 'brand-feature' 'restaurant reference brand composition'
Assert-Contains $majlis 'category-showcase' 'restaurant reference case composition'
Assert-Contains $majlis 'service-canvas' 'restaurant reference service composition'
Assert-Contains $majlis 'micro-footer' 'restaurant reference footer composition'
Assert-Contains $majlis 'majlis-detail-graded.webp' 'restaurant graded detail image'
Assert-UniqueImageSources $majlis 'restaurant case'

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
if ($webpAssets.Count -lt 9) {
  throw 'The public package is missing optimized WebP assets.'
}

foreach ($asset in $webpAssets) {
  if ($asset.Length -gt 500KB) {
    throw "Published WebP asset exceeds 500 KiB: $($asset.Name)"
  }
}

$gradedAssets = @('nadwa-graded.webp', 'nocturne-graded.webp', 'roastery-graded.webp', 'majlis-graded.webp', 'nadwa-detail-graded.webp', 'nocturne-detail-graded.webp', 'roastery-detail-graded.webp', 'majlis-detail-graded.webp')
foreach ($assetName in $gradedAssets) {
  if (-not (Test-Path (Join-Path $siteRoot "assets\\$assetName"))) {
    throw "Missing editorially graded asset: $assetName"
  }
}

$sectorMomentAssets = @(
  'nadwa-moments-01.webp', 'nadwa-moments-02.webp', 'nadwa-moments-03.webp', 'nadwa-moments-04.webp',
  'nocturne-moments-01.webp', 'nocturne-moments-02.webp', 'nocturne-moments-03.webp', 'nocturne-moments-04.webp',
  'roastery-moments-01.webp', 'roastery-moments-02.webp', 'roastery-moments-03.webp', 'roastery-moments-04.webp',
  'majlis-moments-01.webp', 'majlis-moments-02.webp', 'majlis-moments-03.webp', 'majlis-moments-04.webp'
)
foreach ($assetName in $sectorMomentAssets) {
  if (-not (Test-Path (Join-Path $siteRoot "assets\\$assetName"))) {
    throw "Missing sector-specific editorial material: $assetName"
  }
}

$editorialBackground = Join-Path $siteRoot 'assets\\editorial-emerald-background.webp'
if (-not (Test-Path $editorialBackground)) {
  throw 'Missing full-page editorial background asset.'
}

$caseCss = Get-Content -Raw (Join-Path $siteRoot 'assets\\case-editorial.css')
Assert-Contains $caseCss 'editorial-emerald-background.webp' 'reference-style full-page background texture'
Assert-Contains $caseCss 'background-attachment:scroll' 'scrolling page background layer'
Assert-NotContains $caseCss 'background-attachment:fixed' 'fixed viewport background layer'
Assert-Contains $caseCss 'radial-gradient' 'ambient green lighting layer'

$workflow = Get-ChildItem -Path (Split-Path -Parent $siteRoot) -File -Filter '41-*.md' | Select-Object -First 1
if (-not $workflow) {
  throw 'Missing four-sector WhatsApp workflow.'
}

$workflowText = Get-Content -Raw $workflow.FullName
Assert-Contains $workflowText 'WhatsApp Business' 'WhatsApp channel policy'
Assert-Contains $workflowText 'one first-touch channel' 'channel deduplication policy'
Assert-Contains $workflowText 'explicit approval' 'outbound approval policy'
Assert-Contains $workflowText 'https://hwl1117.github.io/kemari-website-ui-portfolio/nadwa/' 'tableware case URL'
Assert-Contains $workflowText 'https://hwl1117.github.io/kemari-website-ui-portfolio/nocturne/' 'fragrance case URL'
Assert-Contains $workflowText 'https://hwl1117.github.io/kemari-website-ui-portfolio/roastery/' 'coffee case URL'
Assert-Contains $workflowText 'https://hwl1117.github.io/kemari-website-ui-portfolio/majlis/' 'restaurant case URL'
Assert-Contains $workflowText 'Never send the portfolio root URL' 'sector-link rule'

Write-Host "Published-site checks passed for $($requiredFiles.Count) pages."
