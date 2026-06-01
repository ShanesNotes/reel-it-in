[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$Episode = "",
    [string]$OutputPath = "",
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
        return $match.Groups["value"].Value.Trim()
    }

    return ""
}

function Get-PublishingField {
    param(
        [string]$Text,
        [string]$Name
    )

    $value = Get-ListField -Text $Text -Name $Name
    if ($value -and $value -ne "TBD") {
        return $value
    }

    return ""
}

function Get-SourceParts {
    param([string]$Value)

    $source = $Value.Trim()
    $url = ""

    $markdownLink = [regex]::Match($source, "\[(?<label>[^\]]+)\]\((?<url>https?://[^\)]+)\)")
    if ($markdownLink.Success) {
        return [pscustomobject]@{
            Source = $markdownLink.Groups["label"].Value.Trim()
            Url = $markdownLink.Groups["url"].Value.Trim()
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

    return [pscustomobject]@{
        Source = $source
        Url = $url
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

        if ([string]::IsNullOrWhiteSpace($headline)) {
            $headline = $block.Groups["title"].Value.Trim()
        }

        $sourceParts = Get-SourceParts -Value $sourceField

        $stories.Add([pscustomobject]@{
            Source = $sourceParts.Source
            Url = $sourceParts.Url
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

function Get-SourceLinks {
    param(
        [object[]]$Stories,
        [string]$SourcesText
    )

    $seen = @{}
    $seenUrls = @{}
    $links = New-Object System.Collections.Generic.List[string]

    foreach ($story in $Stories) {
        if (-not [string]::IsNullOrWhiteSpace($story.Url)) {
            $label = if ($story.Source) { $story.Source } else { $story.Headline }
            $line = "- [$label]($($story.Url))"
            if (-not $seenUrls.ContainsKey($story.Url)) {
                $seenUrls[$story.Url] = $true
                $seen[$line] = $true
                $links.Add($line)
            }
        }
    }

    if ($links.Count -gt 0) {
        return $links.ToArray()
    }

    foreach ($match in [regex]::Matches($SourcesText, 'https?://[^\s<>\)\]"]+')) {
        $url = $match.Value.TrimEnd(".", ",", ";", ":", ")", "]")
        $line = "- $url"
        if (-not $seenUrls.ContainsKey($url) -and -not $seen.ContainsKey($line)) {
            $seenUrls[$url] = $true
            $seen[$line] = $true
            $links.Add($line)
        }
    }

    return $links.ToArray()
}

function Get-BulletSectionItems {
    param(
        [string]$Text,
        [string]$Heading
    )

    $section = Get-MarkdownSection -Text $Text -Heading $Heading
    $items = New-Object System.Collections.Generic.List[string]

    foreach ($line in ($section -split "\r?\n")) {
        if ($line -match "^\s*-\s*(?<value>.+?)\s*$") {
            $value = $Matches["value"].Trim()
            if ($value -and $value -ne "-") {
                $items.Add($value)
            }
        }
    }

    return $items.ToArray()
}

function Get-LiveNoteRows {
    param([string]$ProductionText)

    $section = Get-MarkdownSection -Text $ProductionText -Heading "Live Notes"
    $rows = New-Object System.Collections.Generic.List[object]

    foreach ($line in ($section -split "\r?\n")) {
        if ($line -notmatch "^\|") {
            continue
        }
        if ($line -match "^\|\s*-+\s*\|") {
            continue
        }
        if ($line -match "^\|\s*Timecode\s*\|") {
            continue
        }

        $cells = @($line.Trim('|') -split "\|") | ForEach-Object { $_.Trim() }
        if ($cells.Count -lt 2) {
            continue
        }
        if ([string]::IsNullOrWhiteSpace($cells[0]) -and [string]::IsNullOrWhiteSpace($cells[1])) {
            continue
        }

        $action = if ($cells.Count -ge 3) { $cells[2] } else { "" }
        $rows.Add([pscustomobject]@{
            Timecode = $cells[0]
            Note = $cells[1]
            Action = $action
        })
    }

    return $rows.ToArray()
}

function Get-TableRowsFromSection {
    param([string]$Section)

    $headers = @()
    $rows = New-Object System.Collections.Generic.List[object]

    foreach ($line in ($Section -split "\r?\n")) {
        if ($line -notmatch "^\|") {
            continue
        }

        $cells = @($line.Trim("|") -split "\|") | ForEach-Object { $_.Trim() }
        if (($cells -join "") -match "^-+$") {
            continue
        }

        if ($headers.Count -eq 0) {
            $headers = $cells
            continue
        }

        $row = [ordered]@{}
        for ($i = 0; $i -lt $headers.Count; $i++) {
            $key = $headers[$i]
            $row[$key] = if ($i -lt $cells.Count) { $cells[$i] } else { "" }
        }
        $rows.Add([pscustomobject]$row)
    }

    return $rows.ToArray()
}

function Get-TranscriptChapters {
    param([string]$TranscriptText)

    $chapters = New-Object System.Collections.Generic.List[object]
    $inFence = $false

    foreach ($line in ($TranscriptText -split "\r?\n")) {
        if ($line -match '^\s*```') {
            $inFence = -not $inFence
            continue
        }
        if ($inFence) {
            continue
        }

        $match = [regex]::Match($line, "^\s*(?:\[)?(?<time>\d{1,2}:\d{2}(?::\d{2})?)(?:\])?\s+#+?\s*(?<title>.+)$")
        if (-not $match.Success) {
            $match = [regex]::Match($line, "^\s*##+\s*(?:\[)?(?<time>\d{1,2}:\d{2}(?::\d{2})?)(?:\])?\s*[-:]\s*(?<title>.+)$")
        }

        if ($match.Success) {
            $chapters.Add([pscustomobject]@{
                Timecode = $match.Groups["time"].Value
                Title = $match.Groups["title"].Value.Trim()
            })
        }
    }

    return $chapters.ToArray()
}

function Test-TranscriptContent {
    param([string]$TranscriptText)

    if ([string]::IsNullOrWhiteSpace($TranscriptText)) {
        return $false
    }

    $body = Get-MarkdownSection -Text $TranscriptText -Heading "Transcript"
    if ([string]::IsNullOrWhiteSpace($body)) {
        return $false
    }

    if ($body -match "Paste or link the transcript here") {
        return $false
    }

    return $true
}

function Join-OrTbd {
    param(
        [string[]]$Items,
        [string]$Fallback = "TBD."
    )

    if ($Items.Count -eq 0) {
        return $Fallback
    }

    return ($Items -join "`n")
}

$episodeDir = Resolve-EpisodeDirectory -Value $Episode
$episodeName = Split-Path -Path $episodeDir -Leaf
$episodeText = Get-TextOrEmpty -Path (Join-Path $episodeDir "episode.md")
$sourcesText = Get-TextOrEmpty -Path (Join-Path $episodeDir "sources.md")
$productionText = Get-TextOrEmpty -Path (Join-Path $episodeDir "production-notes.md")
$transcriptText = Get-TextOrEmpty -Path (Join-Path $episodeDir "transcript.md")
$editPlanText = Get-TextOrEmpty -Path (Join-Path $episodeDir "edit-plan.md")
$publishingPath = Join-Path $episodeDir "publishing.md"
$existingPublishing = Get-TextOrEmpty -Path $publishingPath

if ([string]::IsNullOrWhiteSpace($episodeText)) {
    throw "Missing or empty episode.md in $episodeDir"
}

$headingMatch = [regex]::Match($episodeText, "(?m)^#\s+Episode\s+(?<number>\d{3})\s*:\s*(?<label>.+?)\s*$")
$metadata = Get-MarkdownSection -Text $episodeText -Heading "Metadata"
$number = Get-ListField -Text $metadata -Name "Number"
$label = Get-ListField -Text $metadata -Name "Label"
$date = Get-ListField -Text $metadata -Name "Date"

if ([string]::IsNullOrWhiteSpace($number) -and $headingMatch.Success) {
    $number = $headingMatch.Groups["number"].Value
}
if ([string]::IsNullOrWhiteSpace($label) -and $headingMatch.Success) {
    $label = $headingMatch.Groups["label"].Value.Trim()
}
if ([string]::IsNullOrWhiteSpace($number)) {
    $number = $episodeName.Substring(0, [Math]::Min(3, $episodeName.Length))
}
if ([string]::IsNullOrWhiteSpace($label)) {
    $label = $episodeName
}

$stories = Select-MainStories -Stories (Convert-StoryBlocks -Section (Get-MarkdownSection -Text $episodeText -Heading "Selected Stories"))
$sourceLinks = Get-SourceLinks -Stories $stories -SourcesText $sourcesText
$bestMoments = Get-BulletSectionItems -Text $productionText -Heading "Best Moments"
$confusingSpots = Get-BulletSectionItems -Text $productionText -Heading "Confusing Spots"
$editDecisions = Get-BulletSectionItems -Text $productionText -Heading "Edit Decisions"
$liveNotes = Get-LiveNoteRows -ProductionText $productionText
$transcriptChapters = Get-TranscriptChapters -TranscriptText $transcriptText
$editPlanChapters = @(Get-TableRowsFromSection -Section (Get-MarkdownSection -Text $editPlanText -Heading "Chapters"))
$editPlanClips = @(Get-TableRowsFromSection -Section (Get-MarkdownSection -Text $editPlanText -Heading "Clip Candidates"))

$existingTitle = Get-PublishingField -Text $existingPublishing -Name "Final title"
$existingShortTitle = Get-PublishingField -Text $existingPublishing -Name "Short title"
$existingReleaseDate = Get-PublishingField -Text $existingPublishing -Name "Release date"
$existingRuntime = Get-PublishingField -Text $existingPublishing -Name "Runtime"
$existingExplicit = Get-PublishingField -Text $existingPublishing -Name "Explicit"

$finalTitle = if ($existingTitle) { $existingTitle } else { "Reel It In ${number}: $label" }
$shortTitle = if ($existingShortTitle) { $existingShortTitle } else { $label }
$releaseDate = if ($existingReleaseDate) { $existingReleaseDate } else { $date }
$runtime = if ($existingRuntime) { $existingRuntime } else { "" }
$explicit = if ($existingExplicit) { $existingExplicit } else { "No" }

$angle = Get-MarkdownSection -Text $episodeText -Heading "Working Angle"
$angleLines = @($angle -split "\r?\n" | Where-Object { $_.Trim() -and $_ -notmatch "^\d+\." })
$angleSummary = if ($angleLines.Count -gt 0) { $angleLines[0].Trim() } else { "Shane and Dad make this week's AI stories plain." }

$storySummaryLines = New-Object System.Collections.Generic.List[string]
foreach ($story in $stories) {
    if (-not [string]::IsNullOrWhiteSpace($story.Headline)) {
        $why = if ($story.Why) { " $($story.Why)" } else { "" }
        $storySummaryLines.Add("- $($story.Headline)$why")
    }
}

$description = if ($storySummaryLines.Count -gt 0) {
    "$angleSummary`n`nThis episode covers:`n$($storySummaryLines -join "`n")"
}
else {
    "$angleSummary`n`nSelected stories are still TBD."
}

$chapterRows = New-Object System.Collections.Generic.List[string]
if ($transcriptChapters.Count -gt 0) {
    foreach ($chapter in $transcriptChapters) {
        $chapterRows.Add("| $($chapter.Timecode) | $($chapter.Title) |")
    }
}
elseif ($editPlanChapters.Count -gt 0) {
    foreach ($chapter in $editPlanChapters) {
        if (-not [string]::IsNullOrWhiteSpace($chapter.Timecode) -and -not [string]::IsNullOrWhiteSpace($chapter.Title)) {
            $chapterRows.Add("| $($chapter.Timecode) | $($chapter.Title) |")
        }
    }
}
elseif ($liveNotes.Count -gt 0) {
    foreach ($note in $liveNotes) {
        $title = if ($note.Action) { $note.Action } else { $note.Note }
        $chapterRows.Add("| $($note.Timecode) | $title |")
    }
}
else {
    $chapterRows.Add("| 00:00 | Opening |")
}

$clipRows = New-Object System.Collections.Generic.List[string]
foreach ($clip in $editPlanClips | Where-Object { $_.Hook -and $_.Hook -notmatch "(?i)no marked clips|tbd after edit" }) {
    $clipRows.Add("|  | $($clip.Timecode) | $($clip.Hook) | YouTube Shorts / TikTok / Reels |")
}
foreach ($moment in $bestMoments) {
    $clipRows.Add("|  |  | $moment | YouTube Shorts / TikTok / Reels |")
}
foreach ($note in $liveNotes | Where-Object { $_.Action -match "clip|short|pull|highlight" -or $_.Note -match "clip|short|pull|highlight" }) {
    $hook = if ($note.Action) { $note.Action } else { $note.Note }
    $clipRows.Add("|  | $($note.Timecode) | $hook | YouTube Shorts / TikTok / Reels |")
}
if ($clipRows.Count -eq 0) {
    $clipRows.Add("|  |  | TBD after edit | YouTube Shorts / TikTok / Reels |")
}

$sourceBlock = Join-OrTbd -Items $sourceLinks -Fallback "-"
$bestBlock = Join-OrTbd -Items @($bestMoments | ForEach-Object { "- $_" }) -Fallback "- TBD after edit."
$confusingBlock = Join-OrTbd -Items @($confusingSpots | ForEach-Object { "- $_" }) -Fallback "- None logged yet."
$editBlock = Join-OrTbd -Items @($editDecisions | ForEach-Object { "- $_" }) -Fallback "- TBD after edit."
$transcriptValue = if (Test-TranscriptContent -TranscriptText $transcriptText) { "transcript.md" } else { "" }

$youtubeDescription = @"
$description

Sources:
$sourceBlock

Not all the AI news - just what matters, and why.
"@.Trim()

$rssNotes = @"
$description

Sources:
$sourceBlock
"@.Trim()

$shortPost = if ($stories.Count -gt 0) {
    "New Reel It In: Shane and Dad make sense of $($stories.Count) AI stories without letting the jargon win. $shortTitle."
}
else {
    "New Reel It In is in prep: Shane and Dad make AI news plain, one 'so what?' at a time."
}

$newsletter = @"
This week on Reel It In:

$description

Best moments to look for:
$bestBlock
"@.Trim()

$content = @"
# Publishing

Generated by ``tools/generate-publishing-package.ps1`` from ``$episodeName``.

## Final Metadata

- Final title: $finalTitle
- Short title: $shortTitle
- Episode number: $number
- Release date: $releaseDate
- Runtime: $runtime
- Explicit: $explicit

## Description

$description

## Chapters

| Timecode | Title |
| --- | --- |
$($chapterRows -join "`n")

## Source Links

$sourceBlock

## YouTube Package

- Title: $finalTitle
- Description:

$youtubeDescription

- Tags: AI, artificial intelligence, technology, plain English, Reel It In
- Thumbnail idea: Shane and Dad at the table with one plain-English phrase from the strongest story.

## RSS Package

- Episode title: $finalTitle
- Episode summary: $angleSummary
- Episode notes:

$rssNotes

- Transcript: $transcriptValue

## Social Copy

### Short Post

$shortPost

### Newsletter Blurb

$newsletter

### Clip Candidates

| Clip | Timecode | Hook | Platform |
| --- | --- | --- | --- |
$($clipRows -join "`n")

## Edit Package

### Best Moments

$bestBlock

### Confusing Spots

$confusingBlock

### Edit Decisions

$editBlock

## Distribution Checklist

- [ ] Final audio exported.
- [ ] Final video exported if used.
- [ ] Audio mastered or normalized.
- [ ] Source links checked.
- [ ] Transcript checked for obvious errors.
- [ ] YouTube upload checked before public release.
- [ ] RSS episode checked after publish.
- [ ] Apple, Spotify, and YouTube pages checked after release.
"@

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = $publishingPath
}
elseif (-not [System.IO.Path]::IsPathRooted($OutputPath)) {
    $OutputPath = Join-Path $repoRoot $OutputPath
}

$generatedMarker = 'Generated by `tools/generate-publishing-package.ps1`'
$isGenerated = $existingPublishing.Contains($generatedMarker)

if ((Test-Path -LiteralPath $OutputPath) -and -not $Force -and -not $isGenerated -and -not [string]::IsNullOrWhiteSpace($existingPublishing)) {
    Write-Warning "Existing publishing file has manual content. Re-run with -Force to replace it."
    Write-Host "Target: $OutputPath"
    exit 2
}

$wroteOutput = $false
if ($PSCmdlet.ShouldProcess($OutputPath, "Write publishing package")) {
    Set-Content -LiteralPath $OutputPath -Value $content -Encoding utf8
    $wroteOutput = $true
}

if ($wroteOutput) {
    Write-Host "Publishing package written: $OutputPath"
}
else {
    Write-Host "Publishing package target: $OutputPath"
}
Write-Host "Stories: $($stories.Count)"
Write-Host "Source links: $($sourceLinks.Count)"
Write-Host "Chapters: $($chapterRows.Count)"
Write-Host "Clip candidates: $($clipRows.Count)"
