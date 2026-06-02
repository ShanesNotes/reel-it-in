[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$Episode = "",
    [string]$OutputPath = "",
    [string]$DashboardPath = "",
    [switch]$UpdateDashboard
)

$ErrorActionPreference = "Stop"

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
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

function ConvertTo-Slug {
    param([string]$Value)

    $slug = $Value.ToLowerInvariant()
    $slug = [regex]::Replace($slug, "[^a-z0-9]+", "-")
    $slug = $slug.Trim("-")

    if ([string]::IsNullOrWhiteSpace($slug)) {
        return "custom-spark"
    }

    return $slug
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
        $why = Get-ListField -Text $body -Name "Why it matters"
        $question = Get-ListField -Text $body -Name "Dad question"
        $status = Get-ListField -Text $body -Name "Status"

        if ([string]::IsNullOrWhiteSpace($sourceField) -and
            [string]::IsNullOrWhiteSpace($headline) -and
            [string]::IsNullOrWhiteSpace($why)) {
            continue
        }

        if ([string]::IsNullOrWhiteSpace($headline)) {
            $headline = $block.Groups["title"].Value.Trim()
        }

        $sourceParts = Get-SourceParts -Value $sourceField

        $stories.Add([ordered]@{
            source = $sourceParts.Source
            url = $sourceParts.Url
            headline = $headline
            why = $why
            dadQuestion = $question
            status = $status
        })
    }

    return $stories.ToArray()
}

function Select-MainStories {
    param([object[]]$Stories)

    $main = @($Stories | Where-Object {
        [string]::IsNullOrWhiteSpace($_.status) -or $_.status -notmatch "(?i)backup|discard|candidate"
    })

    if ($main.Count -gt 0) {
        return $main
    }

    return @($Stories)
}

function Get-DashboardSparkData {
    param([string]$DashboardFile)

    if (-not (Test-Path -LiteralPath $DashboardFile)) {
        return [pscustomobject]@{
            Keys = @()
            Featured = @()
        }
    }

    $html = Get-Content -LiteralPath $DashboardFile -Raw
    $keys = @([regex]::Matches($html, '(?m)^\s*"([^"]+)"\s*:\s*\{\s*tag:') | ForEach-Object { $_.Groups[1].Value })
    $featuredMatch = [regex]::Match($html, "featuredSparks\s*:\s*\[(?<ids>[^\]]*)\]")
    $featured = @()
    if ($featuredMatch.Success) {
        $featured = @([regex]::Matches($featuredMatch.Groups["ids"].Value, '"([^"]+)"') | ForEach-Object { $_.Groups[1].Value })
    }

    return [pscustomobject]@{
        Keys = $keys
        Featured = $featured
    }
}

function Convert-Sparks {
    param(
        [string]$Section,
        [string[]]$KnownKeys,
        [string[]]$Fallback
    )

    $featured = New-Object System.Collections.Generic.List[string]
    $custom = [ordered]@{}
    $known = @{}

    foreach ($key in $KnownKeys) {
        $known[$key] = $true
    }

    foreach ($line in ($Section -split "\r?\n")) {
        if ($line -notmatch "^\s*-\s*(?<value>.+?)\s*$") {
            continue
        }

        $value = $Matches["value"].Trim().Trim('"', '`')
        if ([string]::IsNullOrWhiteSpace($value)) {
            continue
        }

        if ($known.ContainsKey($value)) {
            $featured.Add($value)
            continue
        }

        $parts = @($value -split "\|") | ForEach-Object { $_.Trim() }
        $id = ConvertTo-Slug $parts[0]
        $suffix = 2
        $baseId = $id
        while ($known.ContainsKey($id) -or $custom.Contains($id)) {
            $id = "$baseId-$suffix"
            $suffix++
        }

        $tag = if ($parts.Count -ge 1 -and $parts[0]) { $parts[0] } else { "Spark" }
        $prompt = if ($parts.Count -ge 2 -and $parts[1]) { $parts[1] } else { $value }
        $aside = if ($parts.Count -ge 3) { $parts[2] } else { "" }

        $custom[$id] = [ordered]@{
            tag = $tag
            prompt = $prompt
            aside = $aside
        }
        $featured.Add($id)
    }

    if ($featured.Count -eq 0) {
        foreach ($id in $Fallback) {
            $featured.Add($id)
        }
    }

    return [pscustomobject]@{
        Featured = $featured.ToArray()
        Custom = $custom
    }
}

$episodeDir = Resolve-EpisodeDirectory -Value $Episode
$episodeFile = Join-Path $episodeDir "episode.md"

if (-not (Test-Path -LiteralPath $episodeFile)) {
    throw "Missing episode file: $episodeFile"
}

if ([string]::IsNullOrWhiteSpace($DashboardPath)) {
    $DashboardPath = Join-Path (Join-Path $repoRoot "app") "reel-it-in.html"
}
elseif (Test-Path -LiteralPath $DashboardPath) {
    $DashboardPath = (Resolve-Path -LiteralPath $DashboardPath).Path
}
else {
    throw "Dashboard path not found: $DashboardPath"
}

$episodeText = Get-Content -LiteralPath $episodeFile -Raw
$episodeName = Split-Path -Path $episodeDir -Leaf
$episodePrefixMatch = [regex]::Match($episodeName, "^(?<number>\d{3})")
$headingMatch = [regex]::Match($episodeText, "(?m)^#\s+Episode\s+(?<number>\d{3})\s*:\s*(?<label>.+?)\s*$")

$metadata = Get-MarkdownSection -Text $episodeText -Heading "Metadata"
$number = Get-ListField -Text $metadata -Name "Number"
$label = Get-ListField -Text $metadata -Name "Label"
$date = Get-ListField -Text $metadata -Name "Date"
$host1 = Get-ListField -Text $metadata -Name "Host 1"
$host2 = Get-ListField -Text $metadata -Name "Host 2"

if ([string]::IsNullOrWhiteSpace($number) -and $headingMatch.Success) {
    $number = $headingMatch.Groups["number"].Value
}
if ([string]::IsNullOrWhiteSpace($number) -and $episodePrefixMatch.Success) {
    $number = $episodePrefixMatch.Groups["number"].Value
}
if ([string]::IsNullOrWhiteSpace($label) -and $headingMatch.Success) {
    $label = $headingMatch.Groups["label"].Value.Trim()
}
if ([string]::IsNullOrWhiteSpace($date)) {
    Write-Warning "No Metadata Date found in episode.md; using today's date for dashboard data."
    $date = Get-Date -Format "yyyy-MM-dd"
}
if ([string]::IsNullOrWhiteSpace($host1)) {
    $host1 = "Shane"
}
if ([string]::IsNullOrWhiteSpace($host2)) {
    $host2 = "Dad"
}

$dashboardSparkData = Get-DashboardSparkData -DashboardFile $DashboardPath
$storySection = Get-MarkdownSection -Text $episodeText -Heading "Selected Stories"
$stories = Select-MainStories -Stories (Convert-StoryBlocks -Section $storySection)
$sparkSection = Get-MarkdownSection -Text $episodeText -Heading "Sparks"
$sparkData = Convert-Sparks -Section $sparkSection -KnownKeys $dashboardSparkData.Keys -Fallback $dashboardSparkData.Featured

$episodeData = [ordered]@{
    number = $number
    label = $label
    date = $date
    hosts = [ordered]@{
        you = $host1
        dad = $host2
    }
    news = @($stories)
    featuredSparks = @($sparkData.Featured)
}

$episodeJson = ($episodeData | ConvertTo-Json -Depth 12)
$customJson = ($sparkData.Custom | ConvertTo-Json -Depth 12)
if ([string]::IsNullOrWhiteSpace($customJson)) {
    $customJson = "{}"
}

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $episodeDir "dashboard-data.js"
}
elseif (-not [System.IO.Path]::IsPathRooted($OutputPath)) {
    $OutputPath = Join-Path $repoRoot $OutputPath
}

$generatedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$relativeEpisode = $episodeDir.Replace("$repoRoot\", "")
$content = @"
// Generated by tools/export-dashboard-data.ps1 on $generatedAt.
// Source episode: $relativeEpisode
// Copy EPISODE into app/reel-it-in.html, or run this script with -UpdateDashboard.
const EPISODE = $episodeJson;

// Custom sparks that are not in the dashboard's SPARK_LIBRARY yet.
// Add these to SPARK_LIBRARY before using their ids in featuredSparks.
const GENERATED_SPARKS = $customJson;
"@

$wroteOutput = $false
if ($PSCmdlet.ShouldProcess($OutputPath, "Write dashboard data")) {
    Set-Content -LiteralPath $OutputPath -Value $content -Encoding utf8
    $wroteOutput = $true
}

if ($wroteOutput) {
    Write-Host "Dashboard data written: $OutputPath"
}
else {
    Write-Host "Dashboard data target: $OutputPath"
}
Write-Host "News items: $($stories.Count)"
Write-Host "Featured sparks: $($sparkData.Featured.Count)"
Write-Host "Custom sparks: $($sparkData.Custom.Count)"

if ($UpdateDashboard) {
    if ($sparkData.Custom.Count -gt 0) {
        Write-Warning "Custom sparks were generated. Add GENERATED_SPARKS to SPARK_LIBRARY before relying on them in Live Mode."
    }

    $html = Get-Content -LiteralPath $DashboardPath -Raw
    $replacement = "  const EPISODE = $episodeJson;"
    $pattern = "(?s)  const EPISODE = \{.*?\};(?=\s*\r?\n\s*const SPARK_LIBRARY)"
    $match = [regex]::Match($html, $pattern)
    if (-not $match.Success) {
        throw "Could not find EPISODE block in dashboard: $DashboardPath"
    }

    $updated = [regex]::Replace($html, $pattern, $replacement, 1)

    if ($PSCmdlet.ShouldProcess($DashboardPath, "Update dashboard EPISODE block")) {
        if ($updated -eq $html) {
            Write-Host "Dashboard EPISODE block already current: $DashboardPath"
        }
        else {
            $utf8NoBom = New-Object System.Text.UTF8Encoding $false
            [System.IO.File]::WriteAllText($DashboardPath, $updated, $utf8NoBom)
            Write-Host "Dashboard EPISODE block updated: $DashboardPath"
        }
    }
}
