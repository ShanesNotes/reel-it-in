[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$Episode = "",
    [string]$OutputPath = "",
    [string]$JsonPath = "",
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

function Get-SourceParts {
    param([string]$Value)

    $label = $Value.Trim()
    $url = ""
    $markdown = [regex]::Match($label, "\[(?<label>[^\]]+)\]\((?<url>https?://[^\)]+)\)")
    if ($markdown.Success) {
        return [pscustomobject]@{
            Label = $markdown.Groups["label"].Value.Trim()
            Url = $markdown.Groups["url"].Value.Trim()
            Markdown = $Value.Trim()
        }
    }

    $urlMatch = [regex]::Match($label, "https?://\S+")
    if ($urlMatch.Success) {
        $url = $urlMatch.Value.TrimEnd(".", ",", ";", ":", ")", "]")
        $label = $label.Replace($urlMatch.Value, "").Trim(" ", "-", ":", "|")
    }

    if ([string]::IsNullOrWhiteSpace($label)) {
        $label = $url
    }

    return [pscustomobject]@{
        Label = $label
        Url = $url
        Markdown = $Value.Trim()
    }
}

function Split-MarkdownRow {
    param([string]$Line)

    return @($Line.Trim().Trim("|") -split "\|") | ForEach-Object { $_.Trim() }
}

function Convert-CandidateRows {
    param([string]$Section)

    $rows = New-Object System.Collections.Generic.List[object]
    $headers = @()

    foreach ($line in ($Section -split "\r?\n")) {
        if ($line -notmatch "^\|") {
            continue
        }

        $cells = Split-MarkdownRow -Line $line
        if (($cells -join "") -match "^-+$") {
            continue
        }

        if ($headers.Count -eq 0) {
            $headers = $cells
            continue
        }

        if ($cells.Count -lt 6) {
            continue
        }

        $source = Get-SourceParts -Value $cells[1]
        if ([string]::IsNullOrWhiteSpace($source.Markdown) -and [string]::IsNullOrWhiteSpace($cells[3])) {
            continue
        }

        $recommendation = $cells[0]
        if ([string]::IsNullOrWhiteSpace($recommendation)) {
            $recommendation = "Candidate"
        }

        $rows.Add([pscustomobject]@{
            Recommendation = $recommendation
            Source = $source.Label
            Url = $source.Url
            SourceMarkdown = $source.Markdown
            Date = $cells[2]
            PlainEnglishNote = $cells[3]
            WhyItMatters = $cells[4]
            DadQuestion = $cells[5]
        })
    }

    return $rows.ToArray()
}

function Format-MarkdownCell {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return ""
    }

    return ($Value -replace "\|", "/").Trim()
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
$sourcesPath = Join-Path $episodeDir "sources.md"
$episodePath = Join-Path $episodeDir "episode.md"
$existingScoutPath = Join-Path $episodeDir "research-scout.md"
$sourcesText = Get-TextOrEmpty -Path $sourcesPath
$episodeText = Get-TextOrEmpty -Path $episodePath
$existingScout = Get-TextOrEmpty -Path $existingScoutPath

if ([string]::IsNullOrWhiteSpace($sourcesText)) {
    throw "Missing or empty sources.md in $episodeDir"
}

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = $existingScoutPath
}
elseif (-not [System.IO.Path]::IsPathRooted($OutputPath)) {
    $OutputPath = Join-Path $repoRoot $OutputPath
}

if ([string]::IsNullOrWhiteSpace($JsonPath)) {
    $JsonPath = Join-Path $episodeDir "research-candidates.json"
}
elseif (-not [System.IO.Path]::IsPathRooted($JsonPath)) {
    $JsonPath = Join-Path $repoRoot $JsonPath
}

$candidateSection = Get-MarkdownSection -Text $sourcesText -Heading "Candidate Stories"
$workingAngle = Get-FirstNonEmptyLine -Text (Get-MarkdownSection -Text $episodeText -Heading "Working Angle")
$candidates = @(Convert-CandidateRows -Section $candidateSection)
$selected = @($candidates | Where-Object { $_.Recommendation -match "(?i)selected" })
$backup = @($candidates | Where-Object { $_.Recommendation -match "(?i)backup|deep" })
$discard = @($candidates | Where-Object { $_.Recommendation -match "(?i)discard" })
$openCandidates = @($candidates | Where-Object {
    $_.Recommendation -notmatch "(?i)selected|backup|deep|discard"
})

$triageRows = New-Object System.Collections.Generic.List[string]
foreach ($candidate in $candidates) {
    $source = if ($candidate.SourceMarkdown) { $candidate.SourceMarkdown } else { $candidate.Source }
    $triageRows.Add("| $(Format-MarkdownCell $candidate.Recommendation) | $(Format-MarkdownCell $source) | $(Format-MarkdownCell $candidate.Date) | $(Format-MarkdownCell $candidate.PlainEnglishNote) | $(Format-MarkdownCell $candidate.WhyItMatters) | $(Format-MarkdownCell $candidate.DadQuestion) |")
}
if ($triageRows.Count -eq 0) {
    $triageRows.Add("| Candidate |  |  |  |  | Why does that matter? |")
}

$missing = New-Object System.Collections.Generic.List[string]
if ($selected.Count -lt 3) {
    $missing.Add("Pick at least $((3 - $selected.Count)) more selected story/stories.")
}
if ([string]::IsNullOrWhiteSpace($workingAngle)) {
    $missing.Add("Write a working episode angle.")
}
if ($candidates.Count -lt 5) {
    $missing.Add("Collect more candidates before locking the slate.")
}
if ($missing.Count -eq 0) {
    $missing.Add("Nothing obvious from the current source table.")
}

$selectedLines = if ($selected.Count -gt 0) {
    ($selected | ForEach-Object { "- $($_.PlainEnglishNote)" }) -join "`n"
}
else {
    "- None selected yet."
}

$backupLines = if ($backup.Count -gt 0) {
    ($backup | ForEach-Object { "- $($_.PlainEnglishNote)" }) -join "`n"
}
else {
    "- None marked as backup yet."
}
$missingLines = ($missing | ForEach-Object { "- $_" }) -join "`n"

$content = @"
# Research Scout

Generated by ``tools/generate-research-scout.ps1`` from ``$episodeName``.

## Scout Goal

Find real, current AI stories that can become plain-English conversation.

Current angle:

$(if ($workingAngle) { $workingAngle } else { "TBD." })

## Candidate Triage

| Recommendation | Source | Date | Plain-English note | Why it matters | Dad question |
| --- | --- | --- | --- | --- | --- |
$($triageRows -join "`n")

## Slate Snapshot

- Selected stories: $($selected.Count)
- Backup stories: $($backup.Count)
- Candidate stories: $($openCandidates.Count)
- Discarded stories: $($discard.Count)
- Total researched stories: $($candidates.Count)

## Selected For Recording

$selectedLines

## Backup / Deep Conversation

$backupLines

## Missing Before Recording

$missingLines

## Codex Research Prompt

Research this week's AI stories for Reel It In. Favor primary sources over summaries. Update ``sources.md``, then regenerate this scout. For each candidate include source URL, source date, plain-English note, why it matters, Dad question, uncertainty, and recommendation: selected candidate, backup/deep conversation, or discard.

Rules:

- Use real sources and dates.
- Do not invent headlines.
- Prefer announcements, policy documents, research releases, product changes, security reports, and major platform shifts.
- Avoid rumor unless clearly labeled.
- Every item must answer "so what?"

## Source Watchlist

- AI labs: OpenAI, Anthropic, Google DeepMind, Google AI, Meta AI, Microsoft AI
- Platforms: Apple, Microsoft, Google, Amazon, NVIDIA, Adobe
- Policy and safety: European Commission, NIST, FTC, White House, UK DSIT
- Developer ecosystem: GitHub, Hugging Face, major API/tooling releases
- Security: Microsoft Security, Google Threat Intelligence, CISA, major incident reports

## Notes For Shane

- Select for conversation, not completeness.
- Dad should get the shape of the story, not a homework packet.
- A weaker source can point to a stronger primary source; do the extra click.
"@

$data = [ordered]@{
    schemaVersion = 1
    generatedAt = (Get-Date).ToString("s")
    episode = $episodeName
    workingAngle = $workingAngle
    counts = [ordered]@{
        selected = $selected.Count
        backup = $backup.Count
        candidate = $openCandidates.Count
        discard = $discard.Count
        total = $candidates.Count
    }
    missingBeforeRecording = $missing.ToArray()
    candidates = @($candidates | ForEach-Object {
        [ordered]@{
            recommendation = $_.Recommendation
            source = $_.Source
            url = $_.Url
            date = $_.Date
            plainEnglishNote = $_.PlainEnglishNote
            whyItMatters = $_.WhyItMatters
            dadQuestion = $_.DadQuestion
        }
    })
}

$generatedMarker = 'Generated by `tools/generate-research-scout.ps1`'
$isGenerated = $existingScout.Contains($generatedMarker)
$looksLikeTemplate = $existingScout.Contains("{{EPISODE_NUMBER}}") -or $existingScout.Contains("Selected stories: 0") -or [string]::IsNullOrWhiteSpace($existingScout)

if ((Test-Path -LiteralPath $OutputPath) -and -not $Force -and -not $isGenerated -and -not $looksLikeTemplate) {
    Write-Warning "Existing research scout has manual content. Re-run with -Force to replace it."
    Write-Host "Target: $OutputPath"
    exit 2
}

if ($PSCmdlet.ShouldProcess($OutputPath, "Write research scout")) {
    Write-Utf8Text -Path $OutputPath -Content $content
}
if ($PSCmdlet.ShouldProcess($JsonPath, "Write research candidate JSON")) {
    Write-Utf8Json -Path $JsonPath -Data $data
}

Write-Host "Research scout written: $OutputPath"
Write-Host "Research candidates JSON written: $JsonPath"
Write-Host "Selected: $($selected.Count)"
Write-Host "Backup: $($backup.Count)"
Write-Host "Candidates: $($openCandidates.Count)"
