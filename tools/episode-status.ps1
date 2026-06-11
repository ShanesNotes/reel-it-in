[CmdletBinding()]
param(
    [string]$Episode = ""
)

$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "Modules/ReelItIn.Tools.psm1") -Force

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$episodesDir = Join-Path $repoRoot "episodes"

$episodeDir = Resolve-ReelItInEpisodeDirectory -EpisodesDir $episodesDir -Value $Episode
$episodeName = Split-Path -Path $episodeDir -Leaf
$requiredFiles = @(
    "episode.md",
    "sources.md",
    "dad-brief.md",
    "production-notes.md",
    "publishing.md"
)
$optionalFiles = @(
    "research-inbox.md",
    "research-inbox.json",
    "research-drafts.md",
    "research-drafts.json",
    "research-scout.md",
    "research-candidates.json",
    "dashboard-data.js",
    "title-thumbnail.md",
    "title-thumbnail.json",
    "thumbnail-images.json",
    "transcript.md",
    "edit-plan.md",
    "edit-plan.json",
    "archive.json",
    "automation-report.md",
    "handoff/session-launch.md",
    "handoff/edit-plan.md",
    "handoff/editor\chapters.csv",
    "handoff/editor\clip-candidates.csv",
    "handoff/editor\transcript-cleanup-checklist.md",
    "handoff/marketing\title-options.md",
    "handoff/marketing\thumbnail-brief.md",
    "handoff/marketing\thumbnail-prompts.txt",
    "handoff/marketing\thumbnail-board.html",
    "handoff/marketing\generated-thumbnails.md",
    "handoff/dad-packet.md",
    "handoff/recording-packet.md",
    "handoff/editor-packet.md",
    "handoff/publishing-packet.md",
    "handoff/marketing\youtube-upload.md",
    "handoff/marketing\youtube-description.txt",
    "handoff/marketing\rss-upload.md",
    "handoff/marketing\social-posts.md",
    "handoff/marketing\newsletter-blurb.md",
    "handoff/marketing\clip-candidates.csv",
    "handoff/marketing\distribution-checklist.md",
    "handoff/marketing\upload-fields.json"
)

$fileRows = foreach ($name in $requiredFiles) {
    $path = Join-ReelItInRelativePath -BasePath $episodeDir -RelativePath $name
    $exists = Test-Path -LiteralPath $path
    $length = 0
    $status = "Missing"

    if ($exists) {
        $item = Get-Item -LiteralPath $path
        $length = $item.Length
        $status = if ($length -gt 0) { "Present" } else { "Empty" }
    }

    [pscustomobject]@{
        File = $name
        Status = $status
        Bytes = $length
    }
}

$optionalRows = foreach ($name in $optionalFiles) {
    $path = Join-ReelItInRelativePath -BasePath $episodeDir -RelativePath $name
    $exists = Test-Path -LiteralPath $path
    $length = 0
    $status = "Missing"

    if ($exists) {
        $item = Get-Item -LiteralPath $path
        $length = $item.Length
        $status = if ($length -gt 0) { "Present" } else { "Empty" }
    }

    [pscustomobject]@{
        File = $name
        Status = $status
        Bytes = $length
    }
}

$urlPattern = 'https?://[^\s<>\)\]"]+'
$allText = Get-ChildItem -LiteralPath $episodeDir -File -Filter "*.md" |
    Where-Object { $_.Name -notin @("automation-report.md", "research-scout.md", "research-inbox.md", "research-drafts.md") } |
    ForEach-Object { Get-Content -LiteralPath $_.FullName -Raw }

$urlCount = ([regex]::Matches(($allText -join "`n"), $urlPattern)).Count
$todoCount = ([regex]::Matches(($allText -join "`n"), "\bTBD\b|:\s*$")).Count

Write-Host "Episode: $episodeName"
Write-Host "Folder:  $episodeDir"
Write-Host ""
$fileRows | Format-Table File, Status, Bytes -AutoSize
Write-Host "Optional artifacts:"
$optionalRows | Format-Table File, Status, Bytes -AutoSize
Write-Host "Source URL count: $urlCount"
Write-Host "Open placeholder count: $todoCount"

$missing = @($fileRows | Where-Object { $_.Status -ne "Present" })
if ($missing.Count -gt 0) {
    Write-Host ""
    Write-Host "Missing or empty required files:"
    $missing | Format-Table File, Status -AutoSize
    exit 1
}

Write-Host ""
Write-Host "Episode workspace has the required files."
