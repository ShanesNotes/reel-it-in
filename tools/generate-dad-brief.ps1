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
        return $match.Groups["value"].Value.Trim().Trim('`')
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
            Label = $markdownLink.Groups["label"].Value.Trim()
            Url = $markdownLink.Groups["url"].Value.Trim()
        }
    }

    $urlMatch = [regex]::Match($source, "https?://\S+")
    if ($urlMatch.Success) {
        $url = $urlMatch.Value.TrimEnd(".", ",", ";", ":", ")", "]")
        $source = $source.Replace($urlMatch.Value, "").Trim(" ", "-", ":", "|")
    }

    return [pscustomobject]@{
        Label = $source
        Url = $url
    }
}

function Convert-StoryBlocks {
    param([string]$Section)

    $stories = New-Object System.Collections.Generic.List[object]
    $blocks = [regex]::Matches($Section, "(?ms)^###\s+(?<title>.+?)\s*\r?\n(?<body>.*?)(?=^###\s+|\z)")

    foreach ($block in $blocks) {
        $body = $block.Groups["body"].Value
        $source = Get-SourceParts -Value (Get-ListField -Text $body -Name "Source")
        $headline = Get-ListField -Text $body -Name "Plain-English headline"
        $what = Get-ListField -Text $body -Name "What happened"
        $why = Get-ListField -Text $body -Name "Why it matters"
        $question = Get-ListField -Text $body -Name "Dad question"
        $status = Get-ListField -Text $body -Name "Status"

        if ([string]::IsNullOrWhiteSpace($headline) -and
            [string]::IsNullOrWhiteSpace($what) -and
            [string]::IsNullOrWhiteSpace($why)) {
            continue
        }

        if ([string]::IsNullOrWhiteSpace($headline)) {
            $headline = $block.Groups["title"].Value.Trim()
        }

        $stories.Add([pscustomobject]@{
            Source = $source.Label
            Url = $source.Url
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

function Get-FirstNonEmptyLine {
    param([string]$Text)

    foreach ($line in ($Text -split "\r?\n")) {
        $value = $line.Trim()
        if ($value -and $value -notmatch "^\d+\.") {
            return $value
        }
    }

    return ""
}

function Use-ExistingOrFallback {
    param(
        [string]$Existing,
        [string]$Fallback
    )

    if (-not [string]::IsNullOrWhiteSpace($Existing) -and $Existing -ne "TBD") {
        return $Existing
    }

    return $Fallback
}

$episodeDir = Resolve-EpisodeDirectory -Value $Episode
$episodeName = Split-Path -Path $episodeDir -Leaf
$episodePath = Join-Path $episodeDir "episode.md"
$existingDadPath = Join-Path $episodeDir "dad-brief.md"
$episodeText = Get-TextOrEmpty -Path $episodePath
$existingDadText = Get-TextOrEmpty -Path $existingDadPath

if ([string]::IsNullOrWhiteSpace($episodeText)) {
    throw "Missing or empty episode.md in $episodeDir"
}

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = $existingDadPath
}
elseif (-not [System.IO.Path]::IsPathRooted($OutputPath)) {
    $OutputPath = Join-Path $repoRoot $OutputPath
}

$headingMatch = [regex]::Match($episodeText, "(?m)^#\s+Episode\s+(?<number>\d{3})\s*:\s*(?<label>.+?)\s*$")
$metadata = Get-MarkdownSection -Text $episodeText -Heading "Metadata"
$workingAngle = Get-MarkdownSection -Text $episodeText -Heading "Working Angle"
$selectedStories = Select-MainStories -Stories (Convert-StoryBlocks -Section (Get-MarkdownSection -Text $episodeText -Heading "Selected Stories"))
$existingRecording = Get-MarkdownSection -Text $existingDadText -Heading "Recording"

$number = Use-ExistingOrFallback -Existing (Get-ListField -Text $metadata -Name "Number") -Fallback $headingMatch.Groups["number"].Value
$label = Use-ExistingOrFallback -Existing (Get-ListField -Text $metadata -Name "Label") -Fallback $headingMatch.Groups["label"].Value
$date = Use-ExistingOrFallback -Existing (Get-ListField -Text $existingRecording -Name "Date") -Fallback (Get-ListField -Text $metadata -Name "Date")
$time = Use-ExistingOrFallback -Existing (Get-ListField -Text $existingRecording -Name "Time") -Fallback ""
$link = Use-ExistingOrFallback -Existing (Get-ListField -Text $existingRecording -Name "Link") -Fallback ""
$theme = Get-FirstNonEmptyLine -Text $workingAngle
if ([string]::IsNullOrWhiteSpace($theme)) {
    $theme = "Shane and Dad make this week's AI stories plain."
}

$storyBlocks = New-Object System.Collections.Generic.List[string]
$storyIndex = 1
foreach ($story in $selectedStories) {
    $plain = if ($story.What) { $story.What } else { $story.Headline }
    $why = if ($story.Why) { $story.Why } else { "This is the part to pull back to normal life." }
    $question = if ($story.DadQuestion) { $story.DadQuestion } else { "Why does that matter?" }

    $storyBlocks.Add(@"
### $storyIndex. $($story.Headline)

- Plain-English version: $plain
- Why it matters: $why
- A good question: $question
"@.Trim())

    $storyIndex++
}

if ($storyBlocks.Count -eq 0) {
    $storyBlocks.Add(@"
### 1. TBD

- Plain-English version:
- Why it matters:
- A good question: Why does that matter?
"@.Trim())
}

$content = @"
# Dad Brief

Generated by ``tools/generate-dad-brief.ps1`` from ``$episodeName``.

## Recording

- Date: $date
- Time: $time
- Link: $link

## Episode Theme

$theme

The job on mic is simple: stay curious, stop Shane when something gets too technical, and keep asking what changes for a normal person.

## What We Might Talk About

$($storyBlocks -join "`n`n")

## Keep It Loose

This is not homework. The point is to stay curious and reel Shane back in when something sounds too technical, too abstract, or too grand.

## Avoid

- Reading from notes on mic
- Trying to sound like an AI expert
- Letting jargon pass without asking what it means
"@

$generatedMarker = 'Generated by `tools/generate-dad-brief.ps1`'
$templateMarker = 'TBD.'
$isGenerated = $existingDadText.Contains($generatedMarker)
$looksLikeTemplate = $existingDadText.Contains($templateMarker) -or [string]::IsNullOrWhiteSpace($existingDadText)

if ((Test-Path -LiteralPath $OutputPath) -and -not $Force -and -not $isGenerated -and -not $looksLikeTemplate) {
    Write-Warning "Existing Dad brief has manual content. Re-run with -Force to replace it."
    Write-Host "Target: $OutputPath"
    exit 2
}

$wroteOutput = $false
if ($PSCmdlet.ShouldProcess($OutputPath, "Write Dad brief")) {
    Set-Content -LiteralPath $OutputPath -Value $content -Encoding utf8
    $wroteOutput = $true
}

if ($wroteOutput) {
    Write-Host "Dad brief written: $OutputPath"
}
else {
    Write-Host "Dad brief target: $OutputPath"
}
Write-Host "Stories: $($selectedStories.Count)"
Write-Host "Episode: $number $label"
