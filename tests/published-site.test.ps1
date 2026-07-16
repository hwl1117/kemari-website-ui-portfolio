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

function Assert-ChoiceVisualSwitching {
  param([string]$Content, [string]$Label)

  $choiceButtons = [regex]::Matches($Content, '<button\b(?=[^>]*\bdata-choice=)[^>]*>')
  if ($choiceButtons.Count -ne 3) {
    throw "${Label} must include exactly three visual choices."
  }

  $choiceImages = @()
  foreach ($button in $choiceButtons) {
    $imageMatch = [regex]::Match($button.Value, '\bdata-image="([^"]+)"')
    if (-not $imageMatch.Success) {
      throw "${Label} choice is missing its image source."
    }

    if ($button.Value -notmatch '\bdata-alt="[^"]+"') {
      throw "${Label} choice is missing descriptive alternative text."
    }

    if ($button.Value -notmatch 'style="--choice-image:url\(''[^'']+''\)"') {
      throw "${Label} choice is missing its visual card preview."
    }

    $choiceImages += $imageMatch.Groups[1].Value
  }

  if (($choiceImages | Select-Object -Unique).Count -ne 3) {
    throw "${Label} choices must use three distinct visuals."
  }

  Assert-Contains $Content 'data-choice-media' "${Label} category media hook"
  Assert-Contains $Content 'categoryImage.src=button.dataset.image' "${Label} category image switch"
  Assert-Contains $Content 'categoryImage.alt=button.dataset.alt' "${Label} category image description switch"
}

function Assert-ProcessVisuals {
  param([string]$Content, [string]$Label)

  $processButtons = [regex]::Matches($Content, '<button\b(?=[^>]*\bdata-step=)[^>]*>')
  if ($processButtons.Count -ne 4) {
    throw "${Label} must include exactly four process stages."
  }

  $processImages = @()
  foreach ($button in $processButtons) {
    $imageMatch = [regex]::Match($button.Value, '\bdata-process-image="([^"]+)"')
    if (-not $imageMatch.Success) {
      throw "${Label} process stage is missing its image source."
    }

    if ($button.Value -notmatch 'style="--process-image:url\(''[^'']+''\)"') {
      throw "${Label} process stage is missing its visual preview."
    }

    $processImages += $imageMatch.Groups[1].Value
  }

  if (($processImages | Select-Object -Unique).Count -ne 4) {
    throw "${Label} process stages must use four distinct visuals."
  }

  Assert-Contains $Content 'data-process-media' "${Label} process image hook"
  Assert-Contains $Content 'processImage.src=button.dataset.processImage' "${Label} process image switch"
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
Assert-Contains $nadwa 'Explore tableware sets' 'tableware merchandising action'
Assert-Contains $nadwa 'Hosting collection / AED 2,380' 'tableware hosting collection route'
Assert-Contains $nadwa 'make hosting, gifting and quantities clear enough to act on.' 'tableware natural commercial framing'
Assert-Contains $nadwa 'Selecting an occasion changes the place settings, serveware and next step' 'tableware clear choice transition'
Assert-Contains $nadwa 'TABLEWARE FOR MEANINGFUL OCCASIONS.' 'tableware natural footer positioning'
Assert-Contains $nadwa 'a single purchase flow.' 'tableware natural purchase flow'
Assert-NotContains $nadwa 'turn a gift into a route with care.' 'tableware literal gifting copy'
Assert-NotContains $nadwa 'catalogue wall.' 'tableware literal catalogue metaphor'
Assert-Contains $nadwa 'COMPOSE THE SET' 'tableware set-building process'
Assert-NotContains $nadwa 'Build a table' 'ambiguous furniture-sales action'
Assert-NotContains $nadwa '<b>HOME TABLE</b>' 'ambiguous furniture home option'
Assert-NotContains $nadwa '<b>HOSTING TABLE</b>' 'ambiguous furniture hosting option'
Assert-NotContains $nadwa 'FROM TABLE TO GIFT' 'ambiguous furniture-sales process heading'
Assert-NotContains $nadwa 'href="../"' 'tableware route back to overview'
Assert-Contains $nadwa 'case-rail' 'tableware editorial rail'
Assert-Contains $nadwa 'editorial-grid' 'tableware grid layout'
Assert-Contains $nadwa 'nadwa-graded.webp' 'tableware graded image'
Assert-Contains $nadwa 'reference-hero' 'tableware reference hero composition'
Assert-Contains $nadwa 'brand-feature' 'tableware reference brand composition'
Assert-Contains $nadwa 'category-showcase' 'tableware reference case composition'
Assert-Contains $nadwa 'service-canvas' 'tableware reference service composition'
Assert-Contains $nadwa 'micro-footer' 'tableware reference footer composition'
Assert-Contains $nadwa 'href="../assets/case-editorial.css?v=20260716-readability"' 'tableware stylesheet cache version'
Assert-Contains $nadwa 'nadwa-detail-graded.webp' 'tableware graded detail image'
Assert-UniqueImageSources $nadwa 'tableware case'
Assert-ChoiceVisualSwitching $nadwa 'tableware case'
Assert-ProcessVisuals $nadwa 'tableware case'
Assert-Contains $nadwa 'CONTINUE THE COLLECTION' 'tableware reordering process stage'
Assert-NotContains $nadwa 'RETURN TO NADWA' 'ambiguous tableware return action'
Assert-Contains $nadwa 'case-main case-main--grainient' 'tableware Grainient scope'
Assert-Contains $nadwa 'data-grainient-background' 'tableware Grainient mount'
Assert-Contains $nadwa '../assets/grainient-background.js' 'tableware Grainient runtime'
Assert-Contains $nadwa 'class="rail-navigation" aria-label="Page sections"' 'tableware rail navigation landmark'
Assert-Contains $nadwa 'href="#nadwa-intro"' 'tableware rail intro anchor'
Assert-Contains $nadwa 'href="#nadwa-story"' 'tableware rail story anchor'
Assert-Contains $nadwa 'href="#table-builder"' 'tableware rail table-builder anchor'
Assert-Contains $nadwa 'href="#nadwa-path"' 'tableware rail process anchor'
Assert-Contains $nadwa 'href="#nadwa-contact"' 'tableware rail contact anchor'
Assert-Contains $nadwa 'data-rail-section' 'tableware rail scrollspy sections'
Assert-Contains $nadwa '../assets/case-rail-navigation.js' 'tableware rail navigation runtime'

$nocturne = Get-Content -Raw (Join-Path $siteRoot 'nocturne\\index.html')
Assert-Contains $nocturne 'Find your scent' 'fragrance discovery route'
Assert-Contains $nocturne 'Discovery set' 'fragrance sample route'
Assert-Contains $nocturne 'Fine fragrance deserves a slower route than a product grid' 'fragrance natural discovery framing'
Assert-Contains $nocturne 'Three intuitive mood-led entry points' 'fragrance clear scent-selection framing'
Assert-Contains $nocturne 'when it is time to replenish.' 'fragrance natural refill language'
Assert-NotContains $nocturne 'the ritual is ready to return.' 'fragrance literal refill language'
Assert-NotContains $nocturne 'href="../"' 'fragrance route back to overview'
Assert-Contains $nocturne 'case-rail' 'fragrance editorial rail'
Assert-Contains $nocturne 'editorial-grid' 'fragrance grid layout'
Assert-Contains $nocturne 'nocturne-graded-v2.webp' 'fragrance refreshed hero image'
Assert-Contains $nocturne 'nocturne-story-v2.webp' 'fragrance refreshed story image'
Assert-Contains $nocturne 'nocturne-choice-after-rain-v2.webp' 'fragrance consistent after-rain choice image'
Assert-Contains $nocturne 'nocturne-choice-late-light-v2.webp' 'fragrance consistent late-light choice image'
Assert-Contains $nocturne 'nocturne-choice-black-silk-v2.webp' 'fragrance consistent black-silk choice image'
Assert-NotContains $nocturne 'nocturne-graded.webp' 'superseded fragrance hero image'
Assert-NotContains $nocturne 'nocturne-hero.webp' 'off-topic fragrance story image'
Assert-Contains $nocturne 'reference-hero' 'fragrance reference hero composition'
Assert-Contains $nocturne 'brand-feature' 'fragrance reference brand composition'
Assert-Contains $nocturne 'category-showcase' 'fragrance reference case composition'
Assert-Contains $nocturne 'service-canvas' 'fragrance reference service composition'
Assert-Contains $nocturne 'micro-footer' 'fragrance reference footer composition'
Assert-Contains $nocturne 'nocturne-detail-graded.webp' 'fragrance graded detail image'
Assert-UniqueImageSources $nocturne 'fragrance case'
Assert-ChoiceVisualSwitching $nocturne 'fragrance case'
Assert-ProcessVisuals $nocturne 'fragrance case'
Assert-Contains $nocturne 'href="../assets/case-editorial.css?v=20260716-readability"' 'fragrance stylesheet cache version'
Assert-Contains $nocturne 'class="rail-navigation" aria-label="Page sections"' 'fragrance rail navigation landmark'
Assert-Contains $nocturne 'href="#nocturne-intro"' 'fragrance rail intro anchor'
Assert-Contains $nocturne 'href="#nocturne-path"' 'fragrance rail process anchor'
Assert-Contains $nocturne 'data-rail-section' 'fragrance rail scrollspy sections'
Assert-Contains $nocturne '../assets/case-rail-navigation.js' 'fragrance rail navigation runtime'
Assert-Contains $nocturne 'case-main case-main--grainient' 'fragrance Grainient scope'
Assert-Contains $nocturne 'data-grainient-background' 'fragrance Grainient mount'
Assert-Contains $nocturne '../assets/grainient-background.js' 'fragrance Grainient runtime'

$roastery = Get-Content -Raw (Join-Path $siteRoot 'roastery\\index.html')
Assert-Contains $roastery 'Choose your roast profile' 'coffee selection route'
Assert-Contains $roastery 'Wholesale coffee' 'coffee wholesale route'
Assert-Contains $roastery 'the promise of a better daily cup.' 'coffee natural hero copy'
Assert-Contains $roastery 'A subscription keeps your taste profile and delivery cadence in one simple plan, with seasonal coffees introduced at the right pace.' 'coffee natural subscription language'
Assert-Contains $roastery 'Start a wholesale conversation with volume, service rhythm and equipment needs.' 'coffee natural wholesale language'
Assert-NotContains $roastery 'roaster rotation in one relationship.' 'coffee literal subscription language'
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
Assert-ChoiceVisualSwitching $roastery 'coffee case'
Assert-ProcessVisuals $roastery 'coffee case'
Assert-Contains $roastery 'href="../assets/case-editorial.css?v=20260716-readability"' 'coffee stylesheet cache version'
Assert-Contains $roastery 'class="rail-navigation" aria-label="Page sections"' 'coffee rail navigation landmark'
Assert-Contains $roastery 'href="#roastery-intro"' 'coffee rail intro anchor'
Assert-Contains $roastery 'href="#roastery-path"' 'coffee rail process anchor'
Assert-Contains $roastery 'data-rail-section' 'coffee rail scrollspy sections'
Assert-Contains $roastery '../assets/case-rail-navigation.js' 'coffee rail navigation runtime'
Assert-Contains $roastery 'case-main case-main--grainient' 'coffee Grainient scope'
Assert-Contains $roastery 'data-grainient-background' 'coffee Grainient mount'
Assert-Contains $roastery '../assets/grainient-background.js' 'coffee Grainient runtime'

$majlis = Get-Content -Raw (Join-Path $siteRoot 'majlis\\index.html')
Assert-Contains $majlis 'Reserve a table' 'restaurant reservation route'
Assert-Contains $majlis 'Private dining' 'restaurant events route'
Assert-Contains $majlis 'MAKE THE EVENING FEEL SETTLED BEFORE YOU RESERVE.' 'restaurant natural hero copy'
Assert-Contains $majlis 'A restaurant site should create the right atmosphere' 'restaurant natural hero framing'
Assert-Contains $majlis 'Visible times give guests a clear choice before they enter the booking flow.' 'restaurant clear reservation transition'
Assert-Contains $majlis 'ONE ROUTE FOR DINNER. ANOTHER FOR A PRIVATE OCCASION.' 'restaurant natural private-event route'
Assert-Contains $majlis 'Thursday / 20:00' 'restaurant unambiguous reservation time'
Assert-NotContains $majlis 'booking with their choice already held.' 'restaurant literal reservation language'
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
Assert-Contains $majlis 'majlis-private-dining-v2.webp' 'restaurant private-dining process image'
Assert-UniqueImageSources $majlis 'restaurant case'
Assert-ChoiceVisualSwitching $majlis 'restaurant case'
Assert-ProcessVisuals $majlis 'restaurant case'
Assert-Contains $majlis 'href="../assets/case-editorial.css?v=20260716-readability"' 'restaurant stylesheet cache version'
Assert-Contains $majlis 'class="rail-navigation" aria-label="Page sections"' 'restaurant rail navigation landmark'
Assert-Contains $majlis 'href="#majlis-intro"' 'restaurant rail intro anchor'
Assert-Contains $majlis 'href="#majlis-path"' 'restaurant rail process anchor'
Assert-Contains $majlis 'data-rail-section' 'restaurant rail scrollspy sections'
Assert-Contains $majlis '../assets/case-rail-navigation.js' 'restaurant rail navigation runtime'
Assert-Contains $majlis 'case-main case-main--grainient' 'restaurant Grainient scope'
Assert-Contains $majlis 'data-grainient-background' 'restaurant Grainient mount'
Assert-Contains $majlis '../assets/grainient-background.js' 'restaurant Grainient runtime'

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

$choiceVisualAssets = @(
  'nadwa-choice-home.webp', 'nadwa-choice-hosting.webp', 'nadwa-choice-gifting.webp',
  'nocturne-choice-after-rain.webp', 'nocturne-choice-late-light.webp', 'nocturne-choice-black-silk.webp',
  'roastery-choice-clean-bright.webp', 'roastery-choice-sweet-round.webp', 'roastery-choice-deep-structured.webp',
  'majlis-choice-early.webp', 'majlis-choice-dinner.webp', 'majlis-choice-late.webp'
)
foreach ($assetName in $choiceVisualAssets) {
  if (-not (Test-Path (Join-Path $siteRoot "assets\\$assetName"))) {
    throw "Missing clickable choice visual: $assetName"
  }
}

$editorialBackground = Join-Path $siteRoot 'assets\\editorial-emerald-structured.webp'
if (-not (Test-Path $editorialBackground)) {
  throw 'Missing sharp full-page editorial background asset.'
}

$caseCss = Get-Content -Raw (Join-Path $siteRoot 'assets\\case-editorial.css')
Assert-NotContains $caseCss 'editorial-emerald-structured.webp' 'unused full-page texture on Grainient cases'
Assert-Contains $caseCss 'background-attachment:scroll' 'scrolling page background layer'
Assert-NotContains $caseCss 'background-attachment:fixed' 'fixed viewport background layer'
Assert-Contains $caseCss 'radial-gradient' 'ambient green lighting layer'
Assert-Contains $caseCss '.choice-preview' 'clickable choice image previews'
Assert-Contains $caseCss '.process-preview' 'process image previews'
Assert-Contains $caseCss '.rail-brand{font-size:16px' 'readable rail identity'
Assert-Contains $caseCss '.rail-brand small{display:block;margin-top:6px;color:var(--case-muted);font-size:13px' 'readable rail brand detail'
Assert-Contains $caseCss '.rail-navigation a b{font-size:13px;font-weight:700}' 'readable rail navigation label'
Assert-Contains $caseCss '.rail-scroll{writing-mode:vertical-rl;color:var(--case-muted);font-size:13px' 'readable rail scroll label'
Assert-Contains $caseCss '.eyebrow{margin:0;color:var(--case-accent);font-size:13px' 'readable eyebrow label'
Assert-Contains $caseCss '.feature-icons span{display:block;margin-top:14px;color:var(--case-muted);font-size:13px' 'readable feature label'
Assert-Contains $caseCss '.category-choice small{display:block;color:var(--case-accent);font-size:13px' 'readable choice number'
Assert-Contains $caseCss '.category-choice span{display:block;margin-top:10px;color:var(--case-muted);font-size:13px' 'readable choice description'
Assert-Contains $caseCss '.service-page{position:absolute;top:28px;right:32px;color:var(--case-muted);font-size:13px' 'readable service page counter'
Assert-Contains $caseCss '.process-step small{display:block;color:var(--case-accent);font-size:13px' 'readable process number'
Assert-Contains $caseCss '.service-visual-column{position:relative;z-index:2;display:grid;padding-top:64px}' 'service visual column'
Assert-Contains $caseCss '.service-status{justify-self:end;width:min(300px,82%);margin:18px 0 0;color:var(--case-soft);font-size:16px' 'service status below the left image'
Assert-NotContains $caseCss '.service-status{position:absolute' 'overlapping process status'
Assert-Contains $caseCss '.footer-meta{display:grid;grid-template-columns:1.2fr .9fr 1.25fr auto;gap:18px;align-items:end;width:min(980px,calc(100% - 11vw));margin:52px auto 0;padding-top:22px;border-top:1px solid var(--case-line);color:var(--case-muted);font-size:14px' 'readable footer metadata'
Assert-Contains $caseCss '.case-main--grainient .editorial-grid{position:relative;z-index:3}' 'tableware Grainient content layering'
Assert-Contains $caseCss '.grainient-background{position:absolute;z-index:1;inset:0;display:block;width:auto;height:auto;overflow:hidden;pointer-events:none}' 'tableware Grainient layer'
Assert-Contains $caseCss '.grainient-canvas{position:absolute;top:0;left:0;display:block;width:100%;height:100vh;will-change:transform}' 'tableware viewport-sized Grainient canvas'
if ($caseCss -notmatch '(?s)\.case-main--grainient\{\s*isolation:isolate;') {
  throw 'Missing tableware Grainient stacking context.'
}
Assert-Contains $caseCss '.case-main--grainient .micro-footer{position:relative;z-index:3}' 'tableware Grainient footer layering'
Assert-Contains $caseCss '.case-main--grainient-fallback{background-color:#0a1d15' 'tableware Grainient CSS fallback'
Assert-Contains $caseCss '@media(prefers-reduced-motion:reduce){.case-main--grainient-fallback{animation:none}}' 'tableware Grainient fallback reduced-motion handling'
Assert-Contains $caseCss '.rail-navigation a[aria-current=page]' 'active rail navigation styling'

$grainientRuntime = Join-Path $siteRoot 'assets\grainient-background.js'
if (-not (Test-Path $grainientRuntime)) {
  throw 'Missing tableware Grainient background runtime.'
}

$refinedMaterialAssets = @(
  'nocturne-graded-v2.webp',
  'nocturne-story-v2.webp',
  'nocturne-choice-after-rain-v2.webp',
  'nocturne-choice-late-light-v2.webp',
  'nocturne-choice-black-silk-v2.webp',
  'majlis-private-dining-v2.webp'
)
foreach ($assetName in $refinedMaterialAssets) {
  if (-not (Test-Path (Join-Path $siteRoot "assets\\$assetName"))) {
    throw "Missing refreshed visual material: $assetName"
  }
}

$processVisualAssets = @(
  'nadwa-process-setting.webp',
  'nadwa-process-hosting.webp',
  'nadwa-process-gifting.webp',
  'nadwa-process-collection.webp'
)
foreach ($assetName in $processVisualAssets) {
  if (-not (Test-Path (Join-Path $siteRoot "assets\\$assetName"))) {
    throw "Missing Nadwa process-stage visual: $assetName"
  }
}

$grainientSource = Get-Content -Raw $grainientRuntime
Assert-Contains $grainientSource "getContext('webgl2'" 'Grainient WebGL2 renderer'
Assert-Contains $grainientSource 'prefers-reduced-motion: reduce' 'Grainient reduced-motion handling'
Assert-Contains $grainientSource 'uScrollOffset' 'Grainient scroll-responsive field'
Assert-Contains $grainientSource 'canvas.style.transform' 'Grainient viewport canvas positioning'
Assert-Contains $grainientSource 'let scrollProgress = 0;' 'Grainient scroll color progress state'
Assert-Contains $grainientSource 'scrollProgress = maxOffset ? localOffset / maxOffset : 0;' 'Grainient normalized page scroll progress'
Assert-Contains $grainientSource 'const updatePaletteForScroll = progress =>' 'Grainient scroll-driven palette interpolation'
Assert-Contains $grainientSource 'activePalette.color1' 'Grainient active scroll palette'
Assert-Contains $grainientSource 'float verticalBlend = 1.0 - S(vertical1, vertical0, transformedUv.y);' 'Grainient defined vertical blend'
Assert-NotContains $grainientSource 'S(vertical0, vertical1, transformedUv.y)' 'Grainient undefined reverse smoothstep'
Assert-Contains $grainientSource 'outputColor = vec4(clamp(color, 0.0, 1.0), 1.0);' 'Grainient fragment output assignment'
Assert-NotContains $grainientSource 'fragColor = vec4(clamp(color, 0.0, 1.0), 1.0);' 'Grainient overwritten fragment output'
Assert-Contains $grainientSource 'const enableFallback = () =>' 'Grainient CSS fallback trigger'
Assert-Contains $grainientSource "canvas.addEventListener('webglcontextlost'" 'Grainient context-loss fallback'
Assert-NotContains $grainientSource "from 'ogl'" 'external Grainient renderer dependency'

$railNavigationRuntime = Join-Path $siteRoot 'assets\case-rail-navigation.js'
if (-not (Test-Path $railNavigationRuntime)) {
  throw 'Missing tableware rail navigation runtime.'
}

$railNavigationSource = Get-Content -Raw $railNavigationRuntime
Assert-Contains $railNavigationSource 'IntersectionObserver' 'rail navigation scrollspy observer'
Assert-Contains $railNavigationSource 'aria-current' 'rail navigation current-section state'

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
