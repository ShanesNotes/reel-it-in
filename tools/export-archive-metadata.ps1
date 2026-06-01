[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$Episode = "",
    [string]$OutputPath = "",
    [switch]$UpdateIndex
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

function Convert-SourceField {
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

        $source = Convert-SourceField -Value $sourceField

        $stories.Add([ordered]@{
            title = $block.Groups["title"].Value.Trim()
            source = $source
            headline = $headline
            whatHappened = $what
            whyItMatters = $why
            dadQuestion = $question
            status = $status
        })
    }

    return $stories.ToArray()
}

function Get-Bullets {
    param(
        [string]$Text,
        [string]$Heading
    )

    $section = Get-AnyMarkdownSection -Text $Text -Heading $Heading
    $items = New-Object System.Collections.Generic.List[string]

    foreach ($line in ($section -split "\r?\n")) {
        if ($line -match "^\s*-\s*(?<value>.+?)\s*$") {
            $value = $Matches["value"].Trim().Trim('"', '`')
            if ($value -and $value -ne "-" -and $value -notmatch "^(?i)tbd\b") {
                $items.Add($value)
            }
        }
    }

    return $items.ToArray()
}

function Get-MarkdownLinks {
    param([string]$Text)

    $links = New-Object System.Collections.Generic.List[object]
    $seen = @{}

    foreach ($match in [regex]::Matches($Text, "\[(?<label>[^\]]+)\]\((?<url>https?://[^\)]+)\)")) {
        $url = $match.Groups["url"].Value.Trim()
        if ($seen.ContainsKey($url)) {
            continue
        }

        $seen[$url] = $true
        $links.Add([ordered]@{
            label = $match.Groups["label"].Value.Trim()
            url = $url
        })
    }

    return $links.ToArray()
}

function Get-TableRows {
    param(
        [string]$Text,
        [string]$Heading
    )

    $section = Get-AnyMarkdownSection -Text $Text -Heading $Heading
    $rows = New-Object System.Collections.Generic.List[object]
    $headers = @()

    foreach ($line in ($section -split "\r?\n")) {
        if ($line -notmatch "^\|") {
            continue
        }

        $cells = @($line.Trim("|") -split "\|") | ForEach-Object { $_.Trim() }
        if ($cells.Count -eq 0) {
            continue
        }
        if (($cells -join "") -match "^-+$") {
            continue
        }

        if ($headers.Count -eq 0) {
            $headers = $cells
            continue
        }
        $rowText = ($cells -join " ").Trim()
        if ($rowText -match "^(?i)tbd\b|(?i)tbd after edit") {
            continue
        }
        if ($rowText -match "(?i)no marked clips yet|no cut list items yet") {
            continue
        }

        $row = [ordered]@{}
        for ($i = 0; $i -lt $headers.Count; $i++) {
            $key = $headers[$i]
            $value = if ($i -lt $cells.Count) { $cells[$i] } else { "" }
            $row[$key] = $value
        }

        $rows.Add($row)
    }

    return $rows.ToArray()
}

function ConvertTo-RelativePath {
    param([string]$Path)

    return $Path.Replace("$repoRoot\", "").Replace("\", "/")
}

function Test-TranscriptContent {
    param([string]$TranscriptText)

    if ([string]::IsNullOrWhiteSpace($TranscriptText)) {
        return $false
    }

    $body = Get-MarkdownSection -Text $TranscriptText -Heading "Transcript"
    return (-not [string]::IsNullOrWhiteSpace($body)) -and ($body -notmatch "Paste or link the transcript here")
}

function Write-Utf8Json {
    param(
        [string]$Path,
        [object]$Data
    )

    $json = $Data | ConvertTo-Json -Depth 20
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($Path, $json + [Environment]::NewLine, $utf8NoBom)
}

function Build-ArchiveMetadata {
    param([string]$EpisodeDir)

    $episodeName = Split-Path -Path $EpisodeDir -Leaf
    $episodeText = Get-TextOrEmpty -Path (Join-Path $EpisodeDir "episode.md")
    $sourcesText = Get-TextOrEmpty -Path (Join-Path $EpisodeDir "sources.md")
    $publishingText = Get-TextOrEmpty -Path (Join-Path $EpisodeDir "publishing.md")
    $productionText = Get-TextOrEmpty -Path (Join-Path $EpisodeDir "production-notes.md")
    $transcriptText = Get-TextOrEmpty -Path (Join-Path $EpisodeDir "transcript.md")
    $editPlanText = Get-TextOrEmpty -Path (Join-Path $EpisodeDir "edit-plan.md")

    if ([string]::IsNullOrWhiteSpace($episodeText)) {
        throw "Missing or empty episode.md in $EpisodeDir"
    }

    $headingMatch = [regex]::Match($episodeText, "(?m)^#\s+Episode\s+(?<number>\d{3})\s*:\s*(?<label>.+?)\s*$")
    $metadata = Get-MarkdownSection -Text $episodeText -Heading "Metadata"
    $status = Get-MarkdownSection -Text $episodeText -Heading "Status"
    $number = Get-ListField -Text $metadata -Name "Number"
    $label = Get-ListField -Text $metadata -Name "Label"

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

    $stories = Convert-StoryBlocks -Section (Get-MarkdownSection -Text $episodeText -Heading "Selected Stories")
    $selectedStories = @($stories | Where-Object {
        [string]::IsNullOrWhiteSpace($_.status) -or $_.status -notmatch "(?i)backup|discard|candidate"
    })
    $backupStories = @($stories | Where-Object { $_.status -match "(?i)backup" })
    $sourceLinks = Get-MarkdownLinks -Text $publishingText
    if ($sourceLinks.Count -eq 0) {
        $sourceLinks = Get-MarkdownLinks -Text $sourcesText
    }

    $recordingSetup = Get-MarkdownSection -Text $productionText -Heading "Recording Setup"
    $researchInboxPath = Join-Path $EpisodeDir "research-inbox.md"
    $researchInboxJsonPath = Join-Path $EpisodeDir "research-inbox.json"
    $researchDraftsPath = Join-Path $EpisodeDir "research-drafts.md"
    $researchDraftsJsonPath = Join-Path $EpisodeDir "research-drafts.json"
    $researchScoutPath = Join-Path $EpisodeDir "research-scout.md"
    $researchCandidatesPath = Join-Path $EpisodeDir "research-candidates.json"
    $dashboardPath = Join-Path $EpisodeDir "dashboard-data.js"
    $titleThumbnailPath = Join-Path $EpisodeDir "title-thumbnail.md"
    $titleThumbnailJsonPath = Join-Path $EpisodeDir "title-thumbnail.json"
    $transcriptPath = Join-Path $EpisodeDir "transcript.md"
    $editPlanPath = Join-Path $EpisodeDir "edit-plan.md"
    $editPlanJsonPath = Join-Path $EpisodeDir "edit-plan.json"
    $archivePath = Join-Path $EpisodeDir "archive.json"

    return [ordered]@{
        schemaVersion = 1
        generatedAt = (Get-Date).ToString("s")
        episode = [ordered]@{
            folder = $episodeName
            number = $number
            label = $label
            status = $status
            recordingDate = Get-ListField -Text $metadata -Name "Date"
            releaseDate = Get-PublishingField -Text $publishingText -Name "Release date"
            runtime = Get-PublishingField -Text $publishingText -Name "Runtime"
            explicit = Get-PublishingField -Text $publishingText -Name "Explicit"
            hosts = [ordered]@{
                you = Get-ListField -Text $metadata -Name "Host 1"
                dad = Get-ListField -Text $metadata -Name "Host 2"
            }
        }
        publishing = [ordered]@{
            finalTitle = Get-PublishingField -Text $publishingText -Name "Final title"
            shortTitle = Get-PublishingField -Text $publishingText -Name "Short title"
            episodeSummary = Get-PublishingField -Text $publishingText -Name "Episode summary"
            transcript = Get-PublishingField -Text $publishingText -Name "Transcript"
            youtubeTitle = Get-PublishingField -Text $publishingText -Name "Title"
            thumbnailIdea = Get-PublishingField -Text $publishingText -Name "Thumbnail idea"
        }
        editorial = [ordered]@{
            workingAngle = Get-MarkdownSection -Text $episodeText -Heading "Working Angle"
            sparks = Get-Bullets -Text $episodeText -Heading "Sparks"
            selectedStories = $selectedStories
            backupStories = $backupStories
            sourceLinks = $sourceLinks
        }
        production = [ordered]@{
            mediaFolder = Get-ListField -Text $recordingSetup -Name "Media folder"
            recordingService = Get-ListField -Text $recordingSetup -Name "Recording service"
            backupRecording = Get-ListField -Text $recordingSetup -Name "Backup recording"
            chapters = @(Get-TableRows -Text $publishingText -Heading "Chapters")
            clipCandidates = @(Get-TableRows -Text $publishingText -Heading "Clip Candidates")
            editPlanChapters = @(Get-TableRows -Text $editPlanText -Heading "Chapters")
            editClipCandidates = @(Get-TableRows -Text $editPlanText -Heading "Clip Candidates")
            cutList = @(Get-TableRows -Text $editPlanText -Heading "Cut Or Repair List")
            bestMoments = @(Get-Bullets -Text $publishingText -Heading "Best Moments")
            editDecisions = @(Get-Bullets -Text $publishingText -Heading "Edit Decisions")
        }
        artifacts = [ordered]@{
            episode = ConvertTo-RelativePath (Join-Path $EpisodeDir "episode.md")
            sources = ConvertTo-RelativePath (Join-Path $EpisodeDir "sources.md")
            researchInbox = if (Test-Path -LiteralPath $researchInboxPath) { ConvertTo-RelativePath $researchInboxPath } else { "" }
            researchInboxJson = if (Test-Path -LiteralPath $researchInboxJsonPath) { ConvertTo-RelativePath $researchInboxJsonPath } else { "" }
            researchDrafts = if (Test-Path -LiteralPath $researchDraftsPath) { ConvertTo-RelativePath $researchDraftsPath } else { "" }
            researchDraftsJson = if (Test-Path -LiteralPath $researchDraftsJsonPath) { ConvertTo-RelativePath $researchDraftsJsonPath } else { "" }
            researchScout = if (Test-Path -LiteralPath $researchScoutPath) { ConvertTo-RelativePath $researchScoutPath } else { "" }
            researchCandidates = if (Test-Path -LiteralPath $researchCandidatesPath) { ConvertTo-RelativePath $researchCandidatesPath } else { "" }
            dadBrief = ConvertTo-RelativePath (Join-Path $EpisodeDir "dad-brief.md")
            productionNotes = ConvertTo-RelativePath (Join-Path $EpisodeDir "production-notes.md")
            publishing = ConvertTo-RelativePath (Join-Path $EpisodeDir "publishing.md")
            dashboardData = if (Test-Path -LiteralPath $dashboardPath) { ConvertTo-RelativePath $dashboardPath } else { "" }
            titleThumbnail = if (Test-Path -LiteralPath $titleThumbnailPath) { ConvertTo-RelativePath $titleThumbnailPath } else { "" }
            titleThumbnailJson = if (Test-Path -LiteralPath $titleThumbnailJsonPath) { ConvertTo-RelativePath $titleThumbnailJsonPath } else { "" }
            transcript = if ((Test-Path -LiteralPath $transcriptPath) -and (Test-TranscriptContent -TranscriptText $transcriptText)) { ConvertTo-RelativePath $transcriptPath } else { "" }
            editPlan = if (Test-Path -LiteralPath $editPlanPath) { ConvertTo-RelativePath $editPlanPath } else { "" }
            editPlanJson = if (Test-Path -LiteralPath $editPlanJsonPath) { ConvertTo-RelativePath $editPlanJsonPath } else { "" }
            archiveMetadata = ConvertTo-RelativePath $archivePath
        }
    }
}

$episodeDir = Resolve-EpisodeDirectory -Value $Episode
$metadata = Build-ArchiveMetadata -EpisodeDir $episodeDir

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $episodeDir "archive.json"
}
elseif (-not [System.IO.Path]::IsPathRooted($OutputPath)) {
    $OutputPath = Join-Path $repoRoot $OutputPath
}

$wroteArchive = $false
if ($PSCmdlet.ShouldProcess($OutputPath, "Write archive metadata")) {
    Write-Utf8Json -Path $OutputPath -Data $metadata
    $wroteArchive = $true
}

if ($wroteArchive) {
    Write-Host "Archive metadata written: $OutputPath"
}
else {
    Write-Host "Archive metadata target: $OutputPath"
}
Write-Host "Selected stories: $(@($metadata.editorial.selectedStories).Count)"
Write-Host "Source links: $(@($metadata.editorial.sourceLinks).Count)"
Write-Host "Clip candidates: $(@($metadata.production.clipCandidates).Count)"

if ($UpdateIndex) {
    $indexPath = Join-Path $episodesDir "index.json"
    $items = New-Object System.Collections.Generic.List[object]

    Get-ChildItem -LiteralPath $episodesDir -Directory |
        Where-Object { $_.Name -match "^\d{3}" } |
        Sort-Object Name |
        ForEach-Object {
            $archiveFile = Join-Path $_.FullName "archive.json"
            if (Test-Path -LiteralPath $archiveFile) {
                $item = Get-Content -LiteralPath $archiveFile -Raw | ConvertFrom-Json
                $items.Add([ordered]@{
                    number = $item.episode.number
                    label = $item.episode.label
                    status = $item.episode.status
                    releaseDate = $item.episode.releaseDate
                    title = $item.publishing.finalTitle
                    folder = $item.episode.folder
                    archiveMetadata = $item.artifacts.archiveMetadata
                })
            }
        }

    $index = [ordered]@{
        schemaVersion = 1
        generatedAt = (Get-Date).ToString("s")
        episodes = $items.ToArray()
    }

    $wroteIndex = $false
    if ($PSCmdlet.ShouldProcess($indexPath, "Write episode archive index")) {
        Write-Utf8Json -Path $indexPath -Data $index
        $wroteIndex = $true
    }

    if ($wroteIndex) {
        Write-Host "Episode index written: $indexPath"
    }
    else {
        Write-Host "Episode index target: $indexPath"
    }
    Write-Host "Indexed episodes: $($items.Count)"
}
