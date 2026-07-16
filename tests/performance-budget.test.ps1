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

$casePages = @(
  'nadwa\\index.html',
  'nocturne\\index.html',
  'roastery\\index.html',
  'majlis\\index.html'
)

foreach ($relativePath in $casePages) {
  $path = Join-Path $siteRoot $relativePath
  $content = Get-Content -Raw $path
  $label = Split-Path -Leaf (Split-Path -Parent $relativePath)

  Assert-Contains $content '<link rel="preload" as="image"' "$label hero preload"
  Assert-Contains $content 'fetchpriority="high"' "$label hero priority"
  Assert-NotContains $content '<video' "$label video payload"
  Assert-NotContains $content '.mp4' "$label MP4 payload"
  Assert-NotContains $content '.webm' "$label WebM payload"
  Assert-NotContains $content 'gsap' "$label GSAP dependency"
  Assert-NotContains $content 'ScrollTrigger' "$label ScrollTrigger dependency"
  Assert-NotContains $content '<script src="http' "$label external script dependency"

  $images = [regex]::Matches($content, '<img\b[^>]*>')
  $eagerImages = @($images | Where-Object { $_.Value -notmatch 'loading="lazy"' })
  $lazyImages = @($images | Where-Object { $_.Value -match 'loading="lazy"' })
  if ($eagerImages.Count -ne 1) {
    throw "$label must load exactly one non-lazy hero image."
  }
  if ($lazyImages.Count -lt 6) {
    throw "$label must defer its supporting editorial images."
  }

  $assetReferences = [regex]::Matches($content, '\.\./assets/([^"'']+\.webp)') | ForEach-Object { $_.Groups[1].Value } | Select-Object -Unique
  foreach ($assetName in $assetReferences) {
    $assetPath = Join-Path $siteRoot "assets\\$assetName"
    if (-not (Test-Path $assetPath)) {
      throw "$label references a missing WebP asset: $assetName"
    }
    if ((Get-Item $assetPath).Length -gt 260KB) {
      throw "$label references an oversized WebP asset: $assetName"
    }
  }
}

$css = Get-Content -Raw (Join-Path $siteRoot 'assets\\case-editorial.css')
Assert-NotContains $css 'editorial-emerald-structured.webp' 'unused background texture request'
if ($css -notmatch '(?s)\.case-main--grainient\{\s*isolation:isolate;\s*background-image:') {
  throw 'Missing Grainient background image override.'
}

$grainient = Get-Content -Raw (Join-Path $siteRoot 'assets\\grainient-background.js')
Assert-Contains $grainient 'const dpr = Math.min(window.devicePixelRatio || 1, 1.25);' 'capped WebGL pixel density'
Assert-Contains $grainient 'const frameInterval = 1000 / 30;' '30fps WebGL budget'
Assert-Contains $grainient 'let scrollFrameId = 0;' 'coalesced scroll state'
Assert-Contains $grainient 'scrollFrameId = requestAnimationFrame' 'scroll frame scheduling'
Assert-NotContains $grainient 'Math.min(window.devicePixelRatio || 1, 1.5)' 'old WebGL pixel density cap'

Write-Host "Performance budgets passed for $($casePages.Count) sector pages."
