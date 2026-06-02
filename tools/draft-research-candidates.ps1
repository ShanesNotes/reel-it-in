[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$Episode = "",
    [string]$InputPath = "",
    [string]$OutputPath = "",
    [string]$JsonPath = "",
    [int]$Top = 10,
    [int]$MinScore = 3,
    [switch]$AppendToSources
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

function Format-MarkdownCell {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return ""
    }

    return ($Value -replace "\|", "/" -replace "\r?\n", " ").Trim()
}

function Get-ExistingUrls {
    param([string]$Text)

    $urls = @{}
    foreach ($match in [regex]::Matches($Text, "https?://[^\s\)\]\|]+")) {
        $url = $match.Value.TrimEnd(".", ",", ";", ":", ")", "]")
        if (-not [string]::IsNullOrWhiteSpace($url)) {
            $urls[$url] = $true
        }
    }

    return $urls
}

function Get-Score {
    param([object]$Item)

    $title = [string]$Item.title
    $summary = [string]$Item.summary
    $category = [string]$Item.category
    $feed = [string]$Item.feed
    $text = "$title $summary $category $feed"
    $score = 0
    $reasons = New-Object System.Collections.Generic.List[string]

    $positivePatterns = @(
        @{ Pattern = "(?i)\bagent|agentic|tool use|workflow|codex\b"; Points = 5; Reason = "agents/tools" },
        @{ Pattern = "(?i)\bsecurity|vulnerabil|ransomware|malicious|dependency|secrets|biodefense\b"; Points = 5; Reason = "security/trust" },
        @{ Pattern = "(?i)\bdiagnos|hospital|patient|health|medical\b"; Points = 5; Reason = "real-world stakes" },
        @{ Pattern = "(?i)\beval|evaluation|benchmark|trustworthy|score below\b"; Points = 4; Reason = "measurement/trust" },
        @{ Pattern = "(?i)\bGemini|OpenAI|GPT|model|frontier|omni\b"; Points = 3; Reason = "model/platform shift" },
        @{ Pattern = "(?i)\bApple Intelligence|accessibility|Siri\b"; Points = 4; Reason = "consumer impact" },
        @{ Pattern = "(?i)\bdeveloper|code|software|enterprise IT|npm|PyTorch\b"; Points = 3; Reason = "developer workflow" },
        @{ Pattern = "(?i)\bpolicy|regulat|standard|NIST|Commission\b"; Points = 4; Reason = "policy/social impact" },
        @{ Pattern = "(?i)\blocal|on-device|privacy\b"; Points = 3; Reason = "where AI runs" }
    )

    foreach ($rule in $positivePatterns) {
        if ($text -match $rule.Pattern) {
            $score += [int]$rule.Points
            $reasons.Add($rule.Reason)
        }
    }

    $negativePatterns = @(
        @{ Pattern = "(?i)\bMagic Quadrant|named a Leader|award|quiz|catch up|demos?\b"; Points = -3; Reason = "likely promotional/filler" },
        @{ Pattern = "(?i)\breturns|sports event|TV\+\b"; Points = -4; Reason = "probably off-format" },
        @{ Pattern = "(?i)\bbeginner.?s guide|profiling in PyTorch\b"; Points = -2; Reason = "too technical/narrow" }
    )

    foreach ($rule in $negativePatterns) {
        if ($text -match $rule.Pattern) {
            $score += [int]$rule.Points
            $reasons.Add($rule.Reason)
        }
    }

    if ($category -match "(?i)Security|Policy") {
        $score += 2
    }
    if ($category -match "(?i)Developer") {
        $score += 1
    }

    $published = [datetime]::MinValue
    if ([datetime]::TryParse([string]$Item.published, [ref]$published)) {
        if ($published -gt (Get-Date).AddDays(-10)) {
            $score += 1
            $reasons.Add("recent")
        }
    }

    return [pscustomobject]@{
        Score = $score
        Reasons = @($reasons | Select-Object -Unique)
    }
}

function Get-WhyItMatters {
    param([object]$Item)

    $text = "$($Item.title) $($Item.summary) $($Item.category)"

    if ($text -match "(?i)\bbiodefense|biosecurity|biological\b") {
        return "This is about whether AI can help defend against biological risks without making dangerous knowledge easier to use."
    }
    if ($text -match "(?i)\bsecurity|vulnerabil|ransomware|malicious|dependency|secrets\b") {
        return "This is about whether the software supply chain and AI-assisted development can be trusted."
    }
    if ($text -match "(?i)\bdiagnos|hospital|patient|health|medical\b") {
        return "This moves AI from demos into decisions around real people and real care."
    }
    if ($text -match "(?i)\beval|evaluation|benchmark|trustworthy|score below\b") {
        return "This is about how we tell whether AI systems are actually reliable enough to use."
    }
    if ($text -match "(?i)\bagent|agentic|codex|developer|code|enterprise IT|workflow\b") {
        return "AI is moving from answering questions into doing work inside professional workflows."
    }
    if ($text -match "(?i)\bApple Intelligence|accessibility|Siri\b") {
        return "This is AI becoming an everyday assistive feature, not a separate chatbot people choose to open."
    }
    if ($text -match "(?i)\bGemini|OpenAI|GPT|model|frontier|omni\b") {
        return "This shows the platform race shifting into tools and experiences normal people may touch."
    }
    if ($text -match "(?i)\blocal|on-device|privacy\b") {
        return "Where the AI runs affects privacy, cost, speed, and who controls the experience."
    }

    return "This may matter if it changes how normal people use, trust, or depend on AI."
}

function Get-DadQuestion {
    param([object]$Item)

    $text = "$($Item.title) $($Item.summary) $($Item.category)"

    if ($text -match "(?i)\bbiodefense|biosecurity|biological\b") {
        return "Is this helping prevent scary biology problems, or teaching people how to make them?"
    }
    if ($text -match "(?i)\bsecurity|vulnerabil|ransomware|malicious|dependency|secrets\b") {
        return "Does this make us safer, or does it give attackers better tools too?"
    }
    if ($text -match "(?i)\bdiagnos|hospital|patient|health|medical\b") {
        return "Who is responsible if the AI helps with a medical decision and gets it wrong?"
    }
    if ($text -match "(?i)\beval|evaluation|benchmark|trustworthy|score below\b") {
        return "How would a normal person know whether this thing is actually reliable?"
    }
    if ($text -match "(?i)\bagent|agentic|codex|developer|code|enterprise IT|workflow\b") {
        return "What is it allowed to do on its own, and who checks the work?"
    }
    if ($text -match "(?i)\bApple Intelligence|accessibility|Siri\b") {
        return "Is this something people will notice, or will it just disappear into the device?"
    }
    if ($text -match "(?i)\bGemini|OpenAI|GPT|model|frontier|omni\b") {
        return "What can this do that last week's AI could not?"
    }
    if ($text -match "(?i)\blocal|on-device|privacy\b") {
        return "Why does it matter whether the AI runs on my device or somewhere else?"
    }

    return "Why does that matter?"
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

if ([string]::IsNullOrWhiteSpace($InputPath)) {
    $InputPath = Join-Path $episodeDir "research-inbox.json"
}
elseif (-not [System.IO.Path]::IsPathRooted($InputPath)) {
    $InputPath = Join-Path $repoRoot $InputPath
}

if (-not (Test-Path -LiteralPath $InputPath)) {
    throw "Research inbox JSON not found: $InputPath. Run collect-research-feeds.ps1 first."
}

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $episodeDir "research-drafts.md"
}
elseif (-not [System.IO.Path]::IsPathRooted($OutputPath)) {
    $OutputPath = Join-Path $repoRoot $OutputPath
}

if ([string]::IsNullOrWhiteSpace($JsonPath)) {
    $JsonPath = Join-Path $episodeDir "research-drafts.json"
}
elseif (-not [System.IO.Path]::IsPathRooted($JsonPath)) {
    $JsonPath = Join-Path $repoRoot $JsonPath
}

$sourcesPath = Join-Path $episodeDir "sources.md"
$sourcesText = if (Test-Path -LiteralPath $sourcesPath) { Get-Content -LiteralPath $sourcesPath -Raw } else { "" }
$existingUrls = Get-ExistingUrls -Text $sourcesText
$inbox = Get-Content -LiteralPath $InputPath -Raw | ConvertFrom-Json
$drafts = New-Object System.Collections.Generic.List[object]

foreach ($item in @($inbox.items)) {
    if ([string]::IsNullOrWhiteSpace($item.url) -or $existingUrls.ContainsKey([string]$item.url)) {
        continue
    }

    $score = Get-Score -Item $item
    $recommendation = if ($score.Score -ge $MinScore) { "Candidate" } else { "Review / likely discard" }
    $source = "[$($item.feed)]($($item.url))"

    $drafts.Add([pscustomobject]@{
        recommendation = $recommendation
        score = $score.Score
        reasons = $score.Reasons
        source = $source
        feed = $item.feed
        url = $item.url
        date = $item.published
        plainEnglishNote = $item.title
        whyItMatters = Get-WhyItMatters -Item $item
        dadQuestion = Get-DadQuestion -Item $item
    })
}

$selectedDrafts = @($drafts |
    Sort-Object @{ Expression = "score"; Descending = $true }, @{ Expression = "date"; Descending = $true }, plainEnglishNote |
    Select-Object -First $Top)

$rows = New-Object System.Collections.Generic.List[string]
foreach ($draft in $selectedDrafts) {
    $rows.Add("| $($draft.recommendation) | $(Format-MarkdownCell $draft.source) | $(Format-MarkdownCell $draft.date) | $(Format-MarkdownCell $draft.plainEnglishNote) | $(Format-MarkdownCell $draft.whyItMatters) | $(Format-MarkdownCell $draft.dadQuestion) |")
}
if ($rows.Count -eq 0) {
    $rows.Add("| Review / likely discard |  |  | No new feed items to draft. |  | Why does that matter? |")
}

$scoreRows = New-Object System.Collections.Generic.List[string]
foreach ($draft in $selectedDrafts) {
    $scoreRows.Add("| $($draft.score) | $(Format-MarkdownCell ($draft.reasons -join ', ')) | $(Format-MarkdownCell $draft.plainEnglishNote) |")
}
if ($scoreRows.Count -eq 0) {
    $scoreRows.Add("| 0 | none | No drafts |")
}

$content = @"
# Research Drafts

Generated by ``tools/draft-research-candidates.ps1`` from ``$episodeName``.

- Input: ``$($InputPath.Replace("$repoRoot\", "").Replace("\", "/"))``
- Minimum candidate score: $MinScore
- Drafts shown: $($selectedDrafts.Count)

## Suggested Candidate Rows

Copy any useful rows into the ``Candidate Stories`` table in ``sources.md``. These are first-pass drafts, not final editorial choices.

| Status | Source | Date | Plain-English note | Why it matters | Dad question |
| --- | --- | --- | --- | --- | --- |
$($rows -join "`n")

## Scoring Notes

| Score | Reasons | Plain-English note |
| ---: | --- | --- |
$($scoreRows -join "`n")

## Human Check

- Confirm the source is primary and current.
- Replace weak "why it matters" copy with Shane's actual editorial take.
- Keep Dad's question simple enough to ask cold.
- Discard platform filler, awards, pure tutorials, and duplicate launch recaps.
"@

$data = [ordered]@{
    schemaVersion = 1
    generatedAt = (Get-Date).ToString("s")
    episode = $episodeName
    input = $InputPath.Replace("$repoRoot\", "").Replace("\", "/")
    top = $Top
    minScore = $MinScore
    drafts = @($selectedDrafts | ForEach-Object {
        [ordered]@{
            recommendation = $_.recommendation
            score = $_.score
            reasons = $_.reasons
            source = $_.source
            feed = $_.feed
            url = $_.url
            date = $_.date
            plainEnglishNote = $_.plainEnglishNote
            whyItMatters = $_.whyItMatters
            dadQuestion = $_.dadQuestion
        }
    })
}

if ($PSCmdlet.ShouldProcess($OutputPath, "Write research drafts")) {
    Write-Utf8Text -Path $OutputPath -Content $content
}
if ($PSCmdlet.ShouldProcess($JsonPath, "Write research drafts JSON")) {
    Write-Utf8Json -Path $JsonPath -Data $data
}

if ($AppendToSources) {
    if ([string]::IsNullOrWhiteSpace($sourcesText)) {
        throw "Cannot append drafts because sources.md is missing or empty: $sourcesPath"
    }

    $candidateRows = ($rows | Where-Object { $_ -notmatch "No new feed items" }) -join "`n"
    if (-not [string]::IsNullOrWhiteSpace($candidateRows)) {
        $updated = [regex]::Replace($sourcesText, "(?m)(?=^## Selected Sources)", "$candidateRows`n`n", 1)
        if ($updated -eq $sourcesText) {
            throw "Could not find '## Selected Sources' marker in $sourcesPath"
        }
        if ($PSCmdlet.ShouldProcess($sourcesPath, "Append research draft rows")) {
            Write-Utf8Text -Path $sourcesPath -Content $updated
        }
    }
}

Write-Host "Research drafts written: $OutputPath"
Write-Host "Research drafts JSON written: $JsonPath"
Write-Host "Drafts: $($selectedDrafts.Count)"
Write-Host "Append to sources: $AppendToSources"
