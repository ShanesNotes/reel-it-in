[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$Episode = "",
    [string]$WatchlistPath = "",
    [string]$OutputPath = "",
    [string]$JsonPath = "",
    [int]$RecentDays = 45,
    [int]$MaxItemsPerFeed = 5,
    [int]$TimeoutSec = 20
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

function ConvertTo-DateTimeOrNull {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $null
    }

    $parsed = [datetime]::MinValue
    if ([datetime]::TryParse($Value, [ref]$parsed)) {
        return $parsed
    }

    return $null
}

function Get-InnerText {
    param([object]$Node)

    if ($null -eq $Node) {
        return ""
    }

    $value = ""
    if ($Node.PSObject.Properties.Name -contains "InnerText") {
        $value = [string]$Node.InnerText
    }
    else {
        $value = [string]$Node
    }

    $value = [System.Net.WebUtility]::HtmlDecode($value)
    if ($value.IndexOf([char]0x00C2) -ge 0 -or $value.IndexOf([char]0x00E2) -ge 0) {
        try {
            $bytes = [System.Text.Encoding]::GetEncoding(1252).GetBytes($value)
            $repaired = [System.Text.Encoding]::UTF8.GetString($bytes)
            if ($repaired -and $repaired.IndexOf([char]0xFFFD) -lt 0) {
                $value = $repaired
            }
        }
        catch {
            # Keep the original value if the repair heuristic is not available.
        }
    }

    $value = $value -replace [char]0x2018, "'"
    $value = $value -replace [char]0x2019, "'"
    $value = $value -replace [char]0x201C, '"'
    $value = $value -replace [char]0x201D, '"'
    $value = $value -replace [char]0x2013, "-"
    $value = $value -replace [char]0x2014, "-"
    $value = $value -replace [char]0x2026, "..."
    $value = $value -replace [char]0x00AE, ""
    $value = $value -replace [char]0x2122, ""
    $value = $value -replace "[^\u0000-\u007F]", ""

    return (($value -replace "<[^>]+>", " ") -replace "\s+", " ").Trim()
}

function Get-AtomLink {
    param([object]$Entry)

    foreach ($link in @($Entry.link)) {
        if ($link.href -and ([string]::IsNullOrWhiteSpace($link.rel) -or $link.rel -eq "alternate")) {
            return ([string]$link.href).Trim()
        }
    }

    return ""
}

function Convert-FeedItems {
    param(
        [xml]$Xml,
        [object]$Feed,
        [datetime]$Cutoff,
        [int]$MaxItems
    )

    $items = New-Object System.Collections.Generic.List[object]

    if ($Xml.rss.channel.item) {
        foreach ($item in @($Xml.rss.channel.item)) {
            $published = ConvertTo-DateTimeOrNull (Get-InnerText $item.pubDate)
            if ($published -and $published -lt $Cutoff) {
                continue
            }

            $items.Add([pscustomobject]@{
                feed = $Feed.name
                category = $Feed.category
                priority = $Feed.priority
                title = Get-InnerText $item.title
                url = Get-InnerText $item.link
                published = if ($published) { $published.ToString("yyyy-MM-dd") } else { "" }
                summary = ((Get-InnerText $item.description) -replace "<[^>]+>", " " -replace "\s+", " ").Trim()
            })

            if ($items.Count -ge $MaxItems) {
                break
            }
        }
    }
    elseif ($Xml.feed.entry) {
        foreach ($entry in @($Xml.feed.entry)) {
            $published = ConvertTo-DateTimeOrNull (Get-InnerText $entry.published)
            if (-not $published) {
                $published = ConvertTo-DateTimeOrNull (Get-InnerText $entry.updated)
            }
            if ($published -and $published -lt $Cutoff) {
                continue
            }

            $items.Add([pscustomobject]@{
                feed = $Feed.name
                category = $Feed.category
                priority = $Feed.priority
                title = Get-InnerText $entry.title
                url = Get-AtomLink $entry
                published = if ($published) { $published.ToString("yyyy-MM-dd") } else { "" }
                summary = ((Get-InnerText $entry.summary) -replace "<[^>]+>", " " -replace "\s+", " ").Trim()
            })

            if ($items.Count -ge $MaxItems) {
                break
            }
        }
    }

    return $items.ToArray()
}

function Test-IncludeItem {
    param(
        [object]$Item,
        [object]$Feed
    )

    if (-not $Feed.includeKeywords) {
        return $true
    }

    $haystack = "$($Item.title) $($Item.summary)"
    foreach ($keyword in @($Feed.includeKeywords)) {
        if ($haystack -match [regex]::Escape($keyword)) {
            return $true
        }
    }

    return $false
}

function Format-MarkdownCell {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return ""
    }

    return ($Value -replace "\|", "/" -replace "\r?\n", " ").Trim()
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

if ([string]::IsNullOrWhiteSpace($WatchlistPath)) {
    $WatchlistPath = Join-Path $repoRoot "docs/RESEARCH_WATCHLIST.json"
}
elseif (-not [System.IO.Path]::IsPathRooted($WatchlistPath)) {
    $WatchlistPath = Join-Path $repoRoot $WatchlistPath
}

if (-not (Test-Path -LiteralPath $WatchlistPath)) {
    throw "Research watchlist not found: $WatchlistPath"
}

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $episodeDir "research-inbox.md"
}
elseif (-not [System.IO.Path]::IsPathRooted($OutputPath)) {
    $OutputPath = Join-Path $repoRoot $OutputPath
}

if ([string]::IsNullOrWhiteSpace($JsonPath)) {
    $JsonPath = Join-Path $episodeDir "research-inbox.json"
}
elseif (-not [System.IO.Path]::IsPathRooted($JsonPath)) {
    $JsonPath = Join-Path $repoRoot $JsonPath
}

$watchlist = Get-Content -LiteralPath $WatchlistPath -Raw | ConvertFrom-Json
$cutoff = (Get-Date).AddDays(-1 * $RecentDays)
$allItems = New-Object System.Collections.Generic.List[object]
$errors = New-Object System.Collections.Generic.List[object]
$userAgent = "ReelItInResearchScout/1.0"

foreach ($feed in @($watchlist.feeds)) {
    try {
        $response = Invoke-WebRequest -Uri $feed.url -Method Get -MaximumRedirection 5 -TimeoutSec $TimeoutSec -UseBasicParsing -UserAgent $userAgent
        $content = $response.Content
        if ($response.RawContentStream) {
            $response.RawContentStream.Position = 0
            $reader = New-Object System.IO.StreamReader($response.RawContentStream, [System.Text.Encoding]::UTF8, $true)
            $content = $reader.ReadToEnd()
            $reader.Close()
        }

        $xml = [xml]$content
        $items = @(Convert-FeedItems -Xml $xml -Feed $feed -Cutoff $cutoff -MaxItems ($MaxItemsPerFeed * 4)) |
            Where-Object { Test-IncludeItem -Item $_ -Feed $feed } |
            Select-Object -First $MaxItemsPerFeed

        foreach ($item in $items) {
            $allItems.Add($item)
        }
    }
    catch {
        $errors.Add([pscustomobject]@{
            feed = $feed.name
            url = $feed.url
            error = $_.Exception.Message
        })
    }
}

$sortedItems = @($allItems | Sort-Object @{ Expression = { if ($_.published) { $_.published } else { "0000-00-00" } }; Descending = $true }, feed, title)
$generatedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$rows = New-Object System.Collections.Generic.List[string]

foreach ($item in $sortedItems) {
    $source = if ($item.url) { "[$($item.feed)]($($item.url))" } else { $item.feed }
    $rows.Add("| Candidate | $(Format-MarkdownCell $source) | $(Format-MarkdownCell $item.published) | $(Format-MarkdownCell $item.title) |  | Why does that matter? |")
}
if ($rows.Count -eq 0) {
    $rows.Add("| Candidate |  |  | No feed items matched the current window. |  | Why does that matter? |")
}

$manualLines = New-Object System.Collections.Generic.List[string]
foreach ($page in @($watchlist.manualPages)) {
    $manualLines.Add("- [$($page.name)]($($page.url)) - $($page.category). $($page.reason)")
}

$errorLines = New-Object System.Collections.Generic.List[string]
foreach ($err in $errors) {
    $errorLines.Add("- $($err.feed): $($err.error)")
}
if ($errorLines.Count -eq 0) {
    $errorLines.Add("- None.")
}

$content = @"
# Research Inbox

Generated by ``tools/collect-research-feeds.ps1`` from ``$episodeName``.

- Generated: $generatedAt
- Recent window: $RecentDays days
- Max items per feed: $MaxItemsPerFeed
- Feed items collected: $($sortedItems.Count)
- Feed errors: $($errors.Count)

## Feed Candidates

Copy promising rows into ``sources.md`` and fill in "Why it matters" before selecting the slate.

| Recommendation | Source | Date | Plain-English note | Why it matters | Dad question |
| --- | --- | --- | --- | --- | --- |
$($rows -join "`n")

## Manual Sources To Check

$($manualLines -join "`n")

## Feed Errors

$($errorLines -join "`n")

## Triage Rules

- Prefer primary sources and dated pages.
- Keep only stories that can answer "so what?"
- Mark the strongest 3 to 5 as Selected in ``sources.md``.
- Mark good tangents as Backup / deep conversation.
- Mark weak, stale, or duplicate items as Discard.
"@

$data = [ordered]@{
    schemaVersion = 1
    generatedAt = (Get-Date).ToString("s")
    episode = $episodeName
    recentDays = $RecentDays
    maxItemsPerFeed = $MaxItemsPerFeed
    watchlist = $WatchlistPath.Replace("$repoRoot\", "").Replace("\", "/")
    itemCount = $sortedItems.Count
    errorCount = $errors.Count
    items = $sortedItems
    errors = $errors.ToArray()
    manualPages = @($watchlist.manualPages)
}

if ($PSCmdlet.ShouldProcess($OutputPath, "Write research inbox")) {
    Write-Utf8Text -Path $OutputPath -Content $content
}
if ($PSCmdlet.ShouldProcess($JsonPath, "Write research inbox JSON")) {
    Write-Utf8Json -Path $JsonPath -Data $data
}

Write-Host "Research inbox written: $OutputPath"
Write-Host "Research inbox JSON written: $JsonPath"
Write-Host "Feed items: $($sortedItems.Count)"
Write-Host "Feed errors: $($errors.Count)"
