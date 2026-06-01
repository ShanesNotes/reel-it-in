[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$Episode = "",
    [string]$OutputDir = ""
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

function Get-AnyMarkdownSection {
    param(
        [string]$Text,
        [string]$Heading
    )

    $escaped = [regex]::Escape($Heading)
    $match = [regex]::Match($Text, "(?ms)^#{2,6}\s+$escaped\s*\r?\n(?<body>.*?)(?=^#{1,6}\s+|\z)")
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

function Get-ListBlock {
    param(
        [string]$Text,
        [string]$Name,
        [string[]]$StopNames
    )

    $escapedName = [regex]::Escape($Name)
    $stopPattern = (($StopNames | ForEach-Object { [regex]::Escape($_) }) -join "|")
    $match = [regex]::Match($Text, "(?ms)^-[ \t]*$escapedName[ \t]*:[ \t]*\r?\n(?<body>.*?)(?=^-[ \t]*(?:$stopPattern)[ \t]*:|\z)")
    if ($match.Success) {
        return $match.Groups["body"].Value.Trim()
    }

    return ""
}

function Get-Links {
    param([string]$Text)

    $links = New-Object System.Collections.Generic.List[object]
    foreach ($match in [regex]::Matches($Text, "\[(?<label>[^\]]+)\]\((?<url>https?://[^\)]+)\)")) {
        $links.Add([ordered]@{
            label = $match.Groups["label"].Value.Trim()
            url = $match.Groups["url"].Value.Trim()
        })
    }

    return $links.ToArray()
}

function Get-TableRows {
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
        $rows.Add($row)
    }

    return $rows.ToArray()
}

function ConvertTo-CsvCell {
    param([string]$Value)

    if ($null -eq $Value) {
        $Value = ""
    }

    return '"' + ($Value -replace '"', '""') + '"'
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
$publishingPath = Join-Path $episodeDir "publishing.md"
$publishingText = Get-TextOrEmpty -Path $publishingPath
$titleThumbnailJsonPath = Join-Path $episodeDir "title-thumbnail.json"

if ([string]::IsNullOrWhiteSpace($publishingText)) {
    throw "Missing or empty publishing.md in $episodeDir"
}

if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $OutputDir = Join-Path (Join-Path $episodeDir "handoff") "marketing"
}
elseif (-not [System.IO.Path]::IsPathRooted($OutputDir)) {
    $OutputDir = Join-Path $repoRoot $OutputDir
}

$finalMetadata = Get-MarkdownSection -Text $publishingText -Heading "Final Metadata"
$description = Get-MarkdownSection -Text $publishingText -Heading "Description"
$chaptersSection = Get-MarkdownSection -Text $publishingText -Heading "Chapters"
$sourceLinksSection = Get-MarkdownSection -Text $publishingText -Heading "Source Links"
$youtubeSection = Get-MarkdownSection -Text $publishingText -Heading "YouTube Package"
$rssSection = Get-MarkdownSection -Text $publishingText -Heading "RSS Package"
$socialSection = Get-MarkdownSection -Text $publishingText -Heading "Social Copy"
$distributionChecklist = Get-MarkdownSection -Text $publishingText -Heading "Distribution Checklist"
$clipSection = Get-AnyMarkdownSection -Text $publishingText -Heading "Clip Candidates"

$finalTitle = Get-ListField -Text $finalMetadata -Name "Final title"
$shortTitle = Get-ListField -Text $finalMetadata -Name "Short title"
$episodeNumber = Get-ListField -Text $finalMetadata -Name "Episode number"
$releaseDate = Get-ListField -Text $finalMetadata -Name "Release date"
$runtime = Get-ListField -Text $finalMetadata -Name "Runtime"
$explicit = Get-ListField -Text $finalMetadata -Name "Explicit"

$youtubeTitle = Get-ListField -Text $youtubeSection -Name "Title"
$youtubeDescription = Get-ListBlock -Text $youtubeSection -Name "Description" -StopNames @("Tags", "Thumbnail idea")
$youtubeTags = Get-ListField -Text $youtubeSection -Name "Tags"
$thumbnailIdea = Get-ListField -Text $youtubeSection -Name "Thumbnail idea"

$rssTitle = Get-ListField -Text $rssSection -Name "Episode title"
$rssSummary = Get-ListField -Text $rssSection -Name "Episode summary"
$rssNotes = Get-ListBlock -Text $rssSection -Name "Episode notes" -StopNames @("Transcript")
$transcript = Get-ListField -Text $rssSection -Name "Transcript"

$shortPost = Get-AnyMarkdownSection -Text $socialSection -Heading "Short Post"
$newsletterBlurb = Get-AnyMarkdownSection -Text $socialSection -Heading "Newsletter Blurb"
$chapters = @(Get-TableRows -Section $chaptersSection)
$clips = @(Get-TableRows -Section $clipSection)
$sourceLinks = @(Get-Links -Text $sourceLinksSection)
$titleThumbnailData = $null
if (Test-Path -LiteralPath $titleThumbnailJsonPath) {
    $titleThumbnailData = Get-Content -LiteralPath $titleThumbnailJsonPath -Raw | ConvertFrom-Json
}

if ([string]::IsNullOrWhiteSpace($youtubeTitle)) { $youtubeTitle = $finalTitle }
if ([string]::IsNullOrWhiteSpace($youtubeDescription)) { $youtubeDescription = $description }
if ([string]::IsNullOrWhiteSpace($rssTitle)) { $rssTitle = $finalTitle }
if ([string]::IsNullOrWhiteSpace($rssSummary)) { $rssSummary = $description.Split("`n")[0].Trim() }
if ([string]::IsNullOrWhiteSpace($rssNotes)) { $rssNotes = $description }

$youtubeUpload = @"
# YouTube Upload

Generated by ``tools/export-marketing-assets.ps1`` from ``$episodeName``.

## Title

$youtubeTitle

## Description

$youtubeDescription

## Tags

$youtubeTags

## Thumbnail Idea

$thumbnailIdea
"@

$rssUpload = @"
# RSS Upload

Generated by ``tools/export-marketing-assets.ps1`` from ``$episodeName``.

## Title

$rssTitle

## Summary

$rssSummary

## Notes

$rssNotes

## Episode Fields

- Episode number: $episodeNumber
- Release date: $releaseDate
- Runtime: $runtime
- Explicit: $explicit
- Transcript: $transcript
"@

$socialPosts = @"
# Social Posts

Generated by ``tools/export-marketing-assets.ps1`` from ``$episodeName``.

## Short Post

$shortPost

## Newsletter Blurb

$newsletterBlurb
"@

$clipCsv = New-Object System.Collections.Generic.List[string]
$clipCsv.Add('"Clip","Timecode","Hook","Platform"')
foreach ($clip in $clips) {
    $clipCsv.Add(@(
        ConvertTo-CsvCell $clip.Clip
        ConvertTo-CsvCell $clip.Timecode
        ConvertTo-CsvCell $clip.Hook
        ConvertTo-CsvCell $clip.Platform
    ) -join ",")
}

$uploadFields = [ordered]@{
    schemaVersion = 1
    generatedAt = (Get-Date).ToString("s")
    episode = [ordered]@{
        folder = $episodeName
        number = $episodeNumber
        title = $finalTitle
        shortTitle = $shortTitle
        releaseDate = $releaseDate
        runtime = $runtime
        explicit = $explicit
    }
    youtube = [ordered]@{
        title = $youtubeTitle
        description = $youtubeDescription
        tags = $youtubeTags
        thumbnailIdea = $thumbnailIdea
    }
    rss = [ordered]@{
        title = $rssTitle
        summary = $rssSummary
        notes = $rssNotes
        transcript = $transcript
    }
    social = [ordered]@{
        shortPost = $shortPost
        newsletterBlurb = $newsletterBlurb
    }
    chapters = $chapters
    sources = $sourceLinks
    clips = $clips
    creative = if ($titleThumbnailData) { $titleThumbnailData } else { [ordered]@{} }
}

if ($PSCmdlet.ShouldProcess($OutputDir, "Write marketing and distribution assets")) {
    New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
    Write-Utf8Text -Path (Join-Path $OutputDir "youtube-upload.md") -Content $youtubeUpload
    Write-Utf8Text -Path (Join-Path $OutputDir "youtube-description.txt") -Content $youtubeDescription
    Write-Utf8Text -Path (Join-Path $OutputDir "rss-upload.md") -Content $rssUpload
    Write-Utf8Text -Path (Join-Path $OutputDir "social-posts.md") -Content $socialPosts
    Write-Utf8Text -Path (Join-Path $OutputDir "newsletter-blurb.md") -Content $newsletterBlurb
    Write-Utf8Text -Path (Join-Path $OutputDir "clip-candidates.csv") -Content ($clipCsv -join "`n")
    Write-Utf8Text -Path (Join-Path $OutputDir "distribution-checklist.md") -Content "# Distribution Checklist`n`n$distributionChecklist"
    Write-Utf8Json -Path (Join-Path $OutputDir "upload-fields.json") -Data $uploadFields
}

Write-Host "Marketing assets written: $OutputDir"
Write-Host "YouTube title: $youtubeTitle"
Write-Host "RSS title: $rssTitle"
Write-Host "Clips: $($clips.Count)"
Write-Host "Source links: $($sourceLinks.Count)"
