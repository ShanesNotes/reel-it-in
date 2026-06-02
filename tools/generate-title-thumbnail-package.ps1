[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$Episode = "",
    [string]$OutputDir = "",
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$episodesDir = Join-Path $repoRoot "episodes"

function Resolve-EpisodeDirectory {
    param([string]$Value)

    if (-not [string]::IsNullOrWhiteSpace($Value)) {
        if (Test-Path -LiteralPath $Value) {
            return (Resolve-Path -LiteralPath $Value).Path
        }

        $candidate = Join-Path $episodesDir $Value
        if (Test-Path -LiteralPath $candidate) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }

        throw "Episode folder not found: $Value"
    }

    $latest = Get-ChildItem -LiteralPath $episodesDir -Directory |
        Where-Object { $_.Name -match "^\d{3}" } |
        Sort-Object Name |
        Select-Object -Last 1

    if (-not $latest) {
        throw "No numbered episode folders found under $episodesDir"
    }

    return $latest.FullName
}

function Get-TextOrEmpty {
    param([string]$Path)

    if (Test-Path -LiteralPath $Path) {
        return Get-Content -LiteralPath $Path -Raw
    }

    return ""
}

function Get-MarkdownSection {
    param(
        [string]$Text,
        [string]$Heading
    )

    $escaped = [regex]::Escape($Heading)
    $match = [regex]::Match($Text, "(?ms)^##\s+$escaped\s*\r?\n(?<body>.*?)(?=^##\s+|\z)")
    if ($match.Success) {
        return $match.Groups["body"].Value.Trim()
    }

    return ""
}

function Get-ListField {
    param(
        [string]$Text,
        [string]$Name
    )

    $escaped = [regex]::Escape($Name)
    $match = [regex]::Match($Text, "(?mi)^-[ \t]*$escaped[ \t]*:[ \t]*(?<value>[^\r\n]*)")
    if ($match.Success) {
        return $match.Groups["value"].Value.Trim().Trim('`')
    }

    return ""
}

function Get-FirstValue {
    param([string[]]$Values)

    foreach ($value in $Values) {
        if (-not [string]::IsNullOrWhiteSpace($value) -and $value -ne "TBD") {
            return $value.Trim()
        }
    }

    return "TBD"
}

function Get-SourceParts {
    param([string]$Value)

    $source = $Value.Trim()
    $url = ""
    $markdownLink = [regex]::Match($source, "\[(?<label>[^\]]+)\]\((?<url>https?://[^\)]+)\)")

    if ($markdownLink.Success) {
        return [ordered]@{
            label = $markdownLink.Groups["label"].Value.Trim()
            url = $markdownLink.Groups["url"].Value.Trim()
        }
    }

    $urlMatch = [regex]::Match($source, "https?://\S+")
    if ($urlMatch.Success) {
        $url = $urlMatch.Value.TrimEnd(".", ",", ";", ":", ")", "]")
        $source = $source.Replace($urlMatch.Value, "").Trim(" ", "-", ":", "|")
    }

    if ([string]::IsNullOrWhiteSpace($source) -and -not [string]::IsNullOrWhiteSpace($url)) {
        $source = $url
    }

    return [ordered]@{
        label = $source
        url = $url
    }
}

function Convert-StoryBlocks {
    param([string]$Section)

    $stories = New-Object System.Collections.Generic.List[object]
    $blocks = [regex]::Matches($Section, "(?ms)^###\s+(?<title>.+?)\s*\r?\n(?<body>.*?)(?=^###\s+|\z)")

    foreach ($block in $blocks) {
        $body = $block.Groups["body"].Value
        $sourceField = Get-ListField -Text $body -Name "Source"
        $headline = Get-ListField -Text $body -Name "Plain-English headline"
        $what = Get-ListField -Text $body -Name "What happened"
        $why = Get-ListField -Text $body -Name "Why it matters"
        $question = Get-ListField -Text $body -Name "Dad question"
        $status = Get-ListField -Text $body -Name "Status"

        if ([string]::IsNullOrWhiteSpace($sourceField) -and
            [string]::IsNullOrWhiteSpace($headline) -and
            [string]::IsNullOrWhiteSpace($why) -and
            [string]::IsNullOrWhiteSpace($what)) {
            continue
        }

        $source = Get-SourceParts -Value $sourceField
        $stories.Add([pscustomobject]@{
            Title = $block.Groups["title"].Value.Trim()
            SourceLabel = $source.label
            SourceUrl = $source.url
            Headline = $headline
            What = $what
            Why = $why
            DadQuestion = $question
            Status = $status
        })
    }

    return $stories.ToArray()
}

function Select-MainStories {
    param([object[]]$Stories)

    $main = @($Stories | Where-Object {
        [string]::IsNullOrWhiteSpace($_.Status) -or $_.Status -notmatch "(?i)backup|discard|candidate"
    })

    if ($main.Count -gt 0) {
        return $main
    }

    return @($Stories)
}

function Test-Theme {
    param(
        [string]$Text,
        [string]$Pattern
    )

    return ($Text -match $Pattern)
}

function Add-UniqueOption {
    param(
        [System.Collections.Generic.List[object]]$Options,
        [hashtable]$Seen,
        [string]$Title,
        [string]$Use,
        [string]$Reason,
        [string]$Risk = ""
    )

    $clean = ($Title -replace "\s+", " ").Trim()
    if ([string]::IsNullOrWhiteSpace($clean)) {
        return
    }

    $key = $clean.ToLowerInvariant()
    if ($Seen.ContainsKey($key)) {
        return
    }

    $Seen[$key] = $true
    $Options.Add([ordered]@{
        title = $clean
        length = $clean.Length
        use = $Use
        reason = $Reason
        risk = $Risk
    })
}

function New-TitleOptions {
    param(
        [object[]]$Stories,
        [string]$Angle,
        [string]$Label
    )

    $allText = (($Stories | ForEach-Object { "$($_.Headline) $($_.What) $($_.Why) $($_.DadQuestion)" }) -join " ") + " " + $Angle
    $hasAct = Test-Theme -Text $allText -Pattern "(?i)\b(act|acts|agent|agentic|helper|doing|keys|tools|connectors)\b"
    $hasSecurity = Test-Theme -Text $allText -Pattern "(?i)\b(security|defense|vulnerabil|attack|flaw|criminal|windows)\b"
    $hasLabels = Test-Theme -Text $allText -Pattern "(?i)\b(label|labels|transparen|trust|deepfake|generated|provenance|AI Act)\b"
    $hasChat = Test-Theme -Text $allText -Pattern "(?i)\b(chatbot|answer|answering|search|assistant)\b"

    $options = New-Object System.Collections.Generic.List[object]
    $seen = @{}

    if ($hasAct) {
        Add-UniqueOption -Options $options -Seen $seen -Title "When AI Starts Doing Things" -Use "YouTube" -Reason "Plain-English hook for agentic AI without jargon."
        Add-UniqueOption -Options $options -Seen $seen -Title "AI Is Leaving The Chatbox" -Use "RSS / YouTube" -Reason "Captures the move from answers to action."
        Add-UniqueOption -Options $options -Seen $seen -Title "Do We Trust AI With The Keys?" -Use "YouTube" -Reason "Turns the agent story into Dad's normal-person question."
    }

    if ($hasSecurity) {
        Add-UniqueOption -Options $options -Seen $seen -Title "AI Found The Cracks" -Use "YouTube" -Reason "Short, concrete security hook."
        Add-UniqueOption -Options $options -Seen $seen -Title "AI Agents Meet Cybersecurity" -Use "RSS" -Reason "Clear for podcast apps and search."
    }

    if ($hasLabels) {
        Add-UniqueOption -Options $options -Seen $seen -Title "The Internet Needs AI Labels" -Use "YouTube / RSS" -Reason "Strong plain-English policy frame."
        Add-UniqueOption -Options $options -Seen $seen -Title "Can We Trust The Label?" -Use "YouTube" -Reason "Good father-son question for the EU transparency story."
    }

    if ($hasAct -and $hasSecurity -and $hasLabels) {
        Add-UniqueOption -Options $options -Seen $seen -Title "AI Gets Tools, Guards, And Labels" -Use "RSS" -Reason "Accurate three-story umbrella."
        Add-UniqueOption -Options $options -Seen $seen -Title "Helpers, Hackers, And Labels" -Use "YouTube" -Reason "Compact thumbnail-friendly summary."
    }

    if ($hasChat) {
        Add-UniqueOption -Options $options -Seen $seen -Title "AI Is More Than Answers Now" -Use "RSS / YouTube" -Reason "Directly names the episode angle."
    }

    Add-UniqueOption -Options $options -Seen $seen -Title "Reel It In $Label" -Use "Fallback" -Reason "Safe if the episode is still being shaped." -Risk "Less clickable."

    return $options.ToArray()
}

function Add-ThumbnailOption {
    param(
        [System.Collections.Generic.List[object]]$Options,
        [string]$Name,
        [string]$Overlay,
        [string]$Visual,
        [string]$Mood,
        [string]$Prompt,
        [string]$Notes
    )

    $Options.Add([ordered]@{
        name = $Name
        overlay = $Overlay
        visual = $Visual
        mood = $Mood
        prompt = $Prompt
        notes = $Notes
    })
}

function New-ThumbnailOptions {
    param(
        [object[]]$Stories,
        [string]$Angle
    )

    $allText = (($Stories | ForEach-Object { "$($_.Headline) $($_.What) $($_.Why) $($_.DadQuestion)" }) -join " ") + " " + $Angle
    $hasAct = Test-Theme -Text $allText -Pattern "(?i)\b(act|acts|agent|agentic|helper|doing|keys|tools|connectors)\b"
    $hasSecurity = Test-Theme -Text $allText -Pattern "(?i)\b(security|defense|vulnerabil|attack|flaw|criminal|windows)\b"
    $hasLabels = Test-Theme -Text $allText -Pattern "(?i)\b(label|labels|transparen|trust|deepfake|generated|provenance|AI Act)\b"

    $options = New-Object System.Collections.Generic.List[object]

    if ($hasAct) {
        Add-ThumbnailOption -Options $options `
            -Name "The Keys" `
            -Overlay "AI HAS KEYS" `
            -Visual "Shane and Dad at a table, one oversized brass key between them, subtle dashboard papers underneath." `
            -Mood "Curious, slightly uneasy, grounded." `
            -Prompt "Warm editorial podcast thumbnail, father and adult son at a table, cream paper texture, warm ink, one brass key as the central object, subtle teal accent, cinematic but natural light, readable overlay text AI HAS KEYS, no fake brand logos, no tiny text, 16:9." `
            -Notes "Best for the agentic AI angle."
    }

    if ($hasSecurity) {
        Add-ThumbnailOption -Options $options `
            -Name "The Crack" `
            -Overlay "AI FOUND IT" `
            -Visual "A printed circuit-board style map with one glowing crack, Shane pointing, Dad skeptical." `
            -Mood "Investigative, high contrast, not alarmist." `
            -Prompt "Warm magazine-style podcast thumbnail, father and adult son reviewing a simple circuit-board map on paper, one visible crack highlighted in gold, cream and ink palette, subtle teal accent, readable overlay text AI FOUND IT, no fake logos, no cybersecurity cliches, 16:9." `
            -Notes "Best for the Microsoft security story."
    }

    if ($hasLabels) {
        Add-ThumbnailOption -Options $options `
            -Name "The Label" `
            -Overlay "AI OR REAL?" `
            -Visual "Two identical-looking cards on a table, one stamped AI, one unstamped, Dad asking the obvious question." `
            -Mood "Plain-English trust question." `
            -Prompt "Editorial podcast thumbnail, father and adult son at a table with two nearly identical printed cards, one stamped AI in gold, cream paper background, warm ink, restrained teal accent, readable overlay text AI OR REAL, grounded and human, no fake logos, 16:9." `
            -Notes "Best for transparency and media-labeling stories."
    }

    Add-ThumbnailOption -Options $options `
        -Name "Three Cards" `
        -Overlay "WHAT MATTERS?" `
        -Visual "Three story cards on the table: AI acts, AI finds flaws, AI gets labels." `
        -Mood "Pilot-friendly, complete episode overview." `
        -Prompt "Warm printed-magazine podcast thumbnail for Reel It In, father and adult son at a table with three bold story cards, labels AI ACTS, SECURITY, LABELS, cream paper, warm ink, one gold accent, subtle teal, readable overlay text WHAT MATTERS, no fake logos, 16:9." `
        -Notes "Best fallback when the episode has multiple equally important stories."

    return $options.ToArray()
}

function ConvertTo-MarkdownTitleTable {
    param([object[]]$Options)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("| Pick | Title | Use | Why | Risk |")
    $lines.Add("| ---: | --- | --- | --- | --- |")
    $index = 1
    foreach ($option in $Options) {
        $risk = if ($option.risk) { $option.risk } else { "-" }
        $lines.Add("| $index | $($option.title) | $($option.use) | $($option.reason) | $risk |")
        $index++
    }

    return ($lines -join "`n")
}

function ConvertTo-MarkdownThumbnailTable {
    param([object[]]$Options)

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("| Pick | Concept | Overlay | Visual | Best Use |")
    $lines.Add("| ---: | --- | --- | --- | --- |")
    $index = 1
    foreach ($option in $Options) {
        $lines.Add("| $index | $($option.name) | $($option.overlay) | $($option.visual) | $($option.notes) |")
        $index++
    }

    return ($lines -join "`n")
}

function ConvertTo-HtmlText {
    param([string]$Value)

    return [System.Net.WebUtility]::HtmlEncode($Value)
}

function New-ThumbnailBoardHtml {
    param(
        [string]$EpisodeName,
        [string]$FinalTitle,
        [object[]]$TitleOptions,
        [object[]]$ThumbnailOptions
    )

    $cards = New-Object System.Collections.Generic.List[string]
    $index = 0
    foreach ($option in $ThumbnailOptions) {
        $title = if ($index -lt $TitleOptions.Count) { $TitleOptions[$index].title } else { $FinalTitle }
        $cards.Add(@"
      <article class="concept">
        <div class="thumb">
          <div class="grain"></div>
          <div class="badge">Reel It In</div>
          <div class="hosts">
            <span>Shane</span>
            <span>Dad</span>
          </div>
          <div class="object">$((ConvertTo-HtmlText $option.name).ToUpperInvariant())</div>
          <h2>$(ConvertTo-HtmlText $option.overlay)</h2>
        </div>
        <div class="copy">
          <p class="meta">Concept $($index + 1)</p>
          <h3>$(ConvertTo-HtmlText $option.name)</h3>
          <p><strong>Title:</strong> $(ConvertTo-HtmlText $title)</p>
          <p><strong>Visual:</strong> $(ConvertTo-HtmlText $option.visual)</p>
          <p><strong>Prompt:</strong> $(ConvertTo-HtmlText $option.prompt)</p>
        </div>
      </article>
"@)
        $index++
    }

    return @"
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Reel It In Thumbnail Board - $EpisodeName</title>
  <style>
    :root {
      --paper: #f7f0df;
      --paper-2: #eadfc7;
      --ink: #221b16;
      --muted: #6f6254;
      --gold: #b9822d;
      --teal: #1d716d;
      --line: rgba(34, 27, 22, .18);
    }
    * { box-sizing: border-box; }
    body {
      margin: 0;
      background: var(--paper);
      color: var(--ink);
      font-family: "Hanken Grotesk", "Segoe UI", Arial, sans-serif;
      line-height: 1.45;
    }
    body::before {
      content: "";
      position: fixed;
      inset: 0;
      pointer-events: none;
      opacity: .13;
      background-image:
        linear-gradient(90deg, rgba(34,27,22,.05) 1px, transparent 1px),
        linear-gradient(rgba(34,27,22,.04) 1px, transparent 1px);
      background-size: 22px 22px;
      mix-blend-mode: multiply;
    }
    header {
      padding: 36px clamp(18px, 4vw, 54px) 20px;
      border-bottom: 1px solid var(--line);
    }
    .eyebrow {
      margin: 0 0 8px;
      color: var(--teal);
      font-size: 12px;
      font-weight: 800;
      letter-spacing: .08em;
      text-transform: uppercase;
    }
    h1 {
      margin: 0;
      max-width: 980px;
      font-family: Georgia, "Times New Roman", serif;
      font-size: clamp(34px, 7vw, 88px);
      line-height: .96;
      letter-spacing: 0;
    }
    header p {
      max-width: 760px;
      color: var(--muted);
      font-size: 18px;
    }
    main {
      padding: 26px clamp(18px, 4vw, 54px) 54px;
    }
    .grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
      gap: 22px;
      align-items: start;
    }
    .concept {
      display: grid;
      gap: 14px;
      min-width: 0;
    }
    .thumb {
      position: relative;
      aspect-ratio: 16 / 9;
      overflow: hidden;
      border: 1px solid rgba(34,27,22,.32);
      background:
        linear-gradient(135deg, rgba(185,130,45,.28), transparent 38%),
        linear-gradient(160deg, var(--paper), var(--paper-2));
      box-shadow: 0 16px 30px rgba(34,27,22,.13);
    }
    .grain {
      position: absolute;
      inset: 0;
      opacity: .16;
      background-image: radial-gradient(rgba(34,27,22,.28) .7px, transparent .7px);
      background-size: 5px 5px;
    }
    .badge {
      position: absolute;
      left: 18px;
      top: 16px;
      padding: 6px 9px;
      border: 1px solid rgba(34,27,22,.28);
      background: rgba(247,240,223,.78);
      font-size: 12px;
      font-weight: 800;
      text-transform: uppercase;
    }
    .hosts {
      position: absolute;
      left: 18px;
      bottom: 18px;
      display: flex;
      gap: 8px;
      color: var(--muted);
      font-size: 12px;
      font-weight: 800;
      text-transform: uppercase;
    }
    .hosts span {
      padding: 6px 8px;
      background: rgba(255,255,255,.36);
      border: 1px solid rgba(34,27,22,.22);
    }
    .object {
      position: absolute;
      right: 16px;
      top: 16px;
      width: 34%;
      min-height: 46%;
      display: grid;
      place-items: center;
      padding: 12px;
      color: var(--paper);
      background: var(--teal);
      border: 2px solid var(--ink);
      font-size: clamp(14px, 2.4vw, 26px);
      font-weight: 900;
      text-align: center;
    }
    .thumb h2 {
      position: absolute;
      left: 18px;
      right: 41%;
      top: 32%;
      margin: 0;
      font-family: Georgia, "Times New Roman", serif;
      font-size: clamp(26px, 3.3vw, 42px);
      line-height: .92;
      letter-spacing: 0;
      text-transform: uppercase;
    }
    .copy {
      border-top: 3px solid var(--gold);
      padding-top: 10px;
    }
    .meta {
      margin: 0 0 4px;
      color: var(--teal);
      font-size: 12px;
      font-weight: 900;
      text-transform: uppercase;
    }
    h3 {
      margin: 0 0 8px;
      font-family: Georgia, "Times New Roman", serif;
      font-size: 26px;
      letter-spacing: 0;
    }
    p {
      margin: 8px 0;
    }
    strong {
      color: var(--ink);
    }
    @media (max-width: 520px) {
      .thumb h2 {
        right: 32%;
        font-size: 30px;
      }
      .object {
        width: 30%;
        font-size: 12px;
      }
    }
  </style>
</head>
<body>
  <header>
    <p class="eyebrow">$EpisodeName title and thumbnail automation</p>
    <h1>$(ConvertTo-HtmlText $FinalTitle)</h1>
    <p>Generated concepts for choosing a title and briefing a thumbnail in Canva, Flow, or an image-generation tool.</p>
  </header>
  <main>
    <section class="grid">
$($cards -join "`n")
    </section>
  </main>
</body>
</html>
"@
}

function Write-Utf8Text {
    param(
        [string]$Path,
        [string]$Content
    )

    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($Path, $Content.Trim() + [Environment]::NewLine, $utf8NoBom)
}

function Write-Utf8Json {
    param(
        [string]$Path,
        [object]$Data
    )

    $json = $Data | ConvertTo-Json -Depth 20
    Write-Utf8Text -Path $Path -Content $json
}

$episodeDir = Resolve-EpisodeDirectory -Value $Episode
$episodeName = Split-Path -Path $episodeDir -Leaf
$episodeText = Get-TextOrEmpty -Path (Join-Path $episodeDir "episode.md")
$publishingText = Get-TextOrEmpty -Path (Join-Path $episodeDir "publishing.md")

if ([string]::IsNullOrWhiteSpace($episodeText)) {
    throw "Missing or empty episode.md in $episodeDir"
}

if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $OutputDir = Join-Path (Join-Path $episodeDir "handoff") "marketing"
}
elseif (-not [System.IO.Path]::IsPathRooted($OutputDir)) {
    $OutputDir = Join-Path $repoRoot $OutputDir
}

$headingMatch = [regex]::Match($episodeText, "(?m)^#\s+Episode\s+(?<number>\d{3})\s*:\s*(?<label>.+?)\s*$")
$metadata = Get-MarkdownSection -Text $episodeText -Heading "Metadata"
$number = Get-FirstValue @((Get-ListField -Text $metadata -Name "Number"), $headingMatch.Groups["number"].Value)
$label = Get-FirstValue @((Get-ListField -Text $metadata -Name "Label"), $headingMatch.Groups["label"].Value, $episodeName)
$angle = Get-MarkdownSection -Text $episodeText -Heading "Working Angle"
$publishingMetadata = Get-MarkdownSection -Text $publishingText -Heading "Final Metadata"
$finalTitle = Get-FirstValue @((Get-ListField -Text $publishingMetadata -Name "Final title"), "Reel It In ${number}: $label")
$stories = Select-MainStories -Stories (Convert-StoryBlocks -Section (Get-MarkdownSection -Text $episodeText -Heading "Selected Stories"))

$titleOptions = @(New-TitleOptions -Stories $stories -Angle $angle -Label $label)
$thumbnailOptions = @(New-ThumbnailOptions -Stories $stories -Angle $angle)

$titleTable = ConvertTo-MarkdownTitleTable -Options $titleOptions
$thumbnailTable = ConvertTo-MarkdownThumbnailTable -Options $thumbnailOptions
$promptLines = New-Object System.Collections.Generic.List[string]
$promptIndex = 1
foreach ($option in $thumbnailOptions) {
    $promptLines.Add("## Prompt $promptIndex - $($option.name)")
    $promptLines.Add("")
    $promptLines.Add($option.prompt)
    $promptLines.Add("")
    $promptLines.Add("Negative guidance: no fake logos, no tiny UI text, no sci-fi neon, no stock-photo gloss, no unreadable overlay.")
    $promptLines.Add("")
    $promptIndex++
}

$packagePath = Join-Path $episodeDir "title-thumbnail.md"
$jsonPath = Join-Path $episodeDir "title-thumbnail.json"
$titleOptionsPath = Join-Path $OutputDir "title-options.md"
$thumbnailBriefPath = Join-Path $OutputDir "thumbnail-brief.md"
$thumbnailPromptsPath = Join-Path $OutputDir "thumbnail-prompts.txt"
$thumbnailBoardPath = Join-Path $OutputDir "thumbnail-board.html"

$generatedMarker = 'Generated by `tools/generate-title-thumbnail-package.ps1`'
$existingPackage = Get-TextOrEmpty -Path $packagePath
$isGenerated = $existingPackage.Contains($generatedMarker)

if ((Test-Path -LiteralPath $packagePath) -and -not $Force -and -not $isGenerated -and -not [string]::IsNullOrWhiteSpace($existingPackage)) {
    Write-Warning "Existing title-thumbnail package has manual content. Re-run with -Force to replace it."
    Write-Host "Target: $packagePath"
    exit 2
}

$sourceLines = if ($stories.Count -gt 0) {
    ($stories | ForEach-Object { "- $($_.Headline)" }) -join "`n"
}
else {
    "- No selected stories found yet."
}

$package = @"
# Title And Thumbnail Package

Generated by ``tools/generate-title-thumbnail-package.ps1`` from ``$episodeName``.

## Episode

- Current title: $finalTitle
- Episode number: $number
- Label: $label

## Episode Frame

$angle

## Selected Story Hooks

$sourceLines

## Recommended Title Options

$titleTable

## Thumbnail Concepts

$thumbnailTable

## Thumbnail Rules

- Keep overlay text to 2 to 5 words.
- Use Shane and Dad as the human signal when possible.
- Use cream paper, warm ink, one gold accent, and teal sparingly.
- Avoid fake company logos or fake UI screenshots.
- The thumbnail should ask the normal-person question before it shows off the technology.

## Image Generation Prompts

$($promptLines -join "`n")
"@

$titleOptionsMd = @"
# Title Options

Generated by ``tools/generate-title-thumbnail-package.ps1`` from ``$episodeName``.

$titleTable

## Recommendation

Pick the title that sounds most like the question Dad would actually ask, then confirm it still describes the episode after the edit is locked.
"@

$thumbnailBrief = @"
# Thumbnail Brief

Generated by ``tools/generate-title-thumbnail-package.ps1`` from ``$episodeName``.

## Direction

Use a warm, printed editorial thumbnail rather than generic AI neon. The recurring visual language is Shane and Dad at the table, one concrete object, and a short plain-English overlay.

## Concepts

$thumbnailTable

## Rules

- 16:9 composition.
- Overlay text must remain readable at phone size.
- No fake logos, no fake UI, no dense source text.
- The image should feel like a human conversation about technology.
- Export finished thumbnails to ``Reel It In Media/$episodeName/thumbnails/``.
"@

$data = [ordered]@{
    schemaVersion = 1
    generatedAt = (Get-Date).ToString("s")
    episode = [ordered]@{
        folder = $episodeName
        number = $number
        label = $label
        currentTitle = $finalTitle
    }
    titleOptions = $titleOptions
    thumbnailOptions = $thumbnailOptions
    artifacts = [ordered]@{
        package = "episodes/$episodeName/title-thumbnail.md"
        titleOptions = "episodes/$episodeName/handoff/marketing/title-options.md"
        thumbnailBrief = "episodes/$episodeName/handoff/marketing/thumbnail-brief.md"
        thumbnailPrompts = "episodes/$episodeName/handoff/marketing/thumbnail-prompts.txt"
        thumbnailBoard = "episodes/$episodeName/handoff/marketing/thumbnail-board.html"
    }
}

if ($PSCmdlet.ShouldProcess($episodeDir, "Write title and thumbnail package")) {
    New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
    Write-Utf8Text -Path $packagePath -Content $package
    Write-Utf8Json -Path $jsonPath -Data $data
    Write-Utf8Text -Path $titleOptionsPath -Content $titleOptionsMd
    Write-Utf8Text -Path $thumbnailBriefPath -Content $thumbnailBrief
    Write-Utf8Text -Path $thumbnailPromptsPath -Content ($promptLines -join "`n")
    Write-Utf8Text -Path $thumbnailBoardPath -Content (New-ThumbnailBoardHtml -EpisodeName $episodeName -FinalTitle $finalTitle -TitleOptions $titleOptions -ThumbnailOptions $thumbnailOptions)
}

Write-Host "Title and thumbnail package written: $packagePath"
Write-Host "Title options: $($titleOptions.Count)"
Write-Host "Thumbnail options: $($thumbnailOptions.Count)"
Write-Host "Thumbnail board: $thumbnailBoardPath"
