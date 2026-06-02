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

function Format-Section {
    param(
        [string]$Value,
        [string]$Fallback = "TBD."
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $Fallback
    }

    return $Value.Trim()
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

        $cells = @($line.Trim("|") -split "\|") | ForEach-Object { $_.Trim() }
        if ($cells.Count -lt 2) {
            continue
        }
        if ([string]::IsNullOrWhiteSpace($cells[0]) -and [string]::IsNullOrWhiteSpace($cells[1])) {
            continue
        }

        $action = if ($cells.Count -ge 3) { $cells[2] } else { "" }
        $rows.Add([ordered]@{
            Timecode = $cells[0]
            Note = $cells[1]
            Action = $action
        })
    }

    return $rows.ToArray()
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

function Get-TranscriptStatus {
    param([string]$TranscriptText)

    if ([string]::IsNullOrWhiteSpace($TranscriptText)) {
        return "Missing"
    }

    if (Test-TranscriptContent -TranscriptText $TranscriptText) {
        return "Transcript ready for edit planning"
    }

    return "Template present; transcript not added yet"
}

function Normalize-Timecode {
    param([string]$Value)

    $time = $Value.Trim().Trim("[", "]")
    $match = [regex]::Match($time, "^(?<h>\d{1,2}:)?(?<m>\d{1,2}):(?<s>\d{2})$")
    if (-not $match.Success) {
        return $time
    }

    if ($match.Groups["h"].Success -and -not [string]::IsNullOrWhiteSpace($match.Groups["h"].Value)) {
        $hour = [int]($match.Groups["h"].Value.TrimEnd(":"))
        $minute = [int]$match.Groups["m"].Value
        return ("{0}:{1:D2}:{2}" -f $hour, $minute, $match.Groups["s"].Value)
    }

    $minuteOnly = [int]$match.Groups["m"].Value
    return ("{0:D2}:{1}" -f $minuteOnly, $match.Groups["s"].Value)
}

function Add-Chapter {
    param(
        [System.Collections.Generic.List[object]]$Rows,
        [hashtable]$Seen,
        [string]$Timecode,
        [string]$Title,
        [string]$Source
    )

    if ([string]::IsNullOrWhiteSpace($Timecode) -or [string]::IsNullOrWhiteSpace($Title)) {
        return
    }

    $time = Normalize-Timecode -Value $Timecode
    $cleanTitle = ($Title -replace "\s+", " ").Trim(" ", "-", ":", "|")
    if ([string]::IsNullOrWhiteSpace($cleanTitle)) {
        return
    }

    $key = "$time|$cleanTitle"
    if ($Seen.ContainsKey($key)) {
        return
    }

    $Seen[$key] = $true
    $Rows.Add([ordered]@{
        Timecode = $time
        Title = $cleanTitle
        Source = $Source
    })
}

function Get-Chapters {
    param(
        [string]$TranscriptText,
        [string]$ProductionText
    )

    $rows = New-Object System.Collections.Generic.List[object]
    $seen = @{}
    $hasTranscript = Test-TranscriptContent -TranscriptText $TranscriptText

    if ($hasTranscript) {
        $chapterSection = Get-AnyMarkdownSection -Text $TranscriptText -Heading "Chapter Markers"
        foreach ($line in ($chapterSection -split "\r?\n")) {
            $match = [regex]::Match($line, "^\s*(?:[-*]\s*)?(?:#{1,6}\s*)?(?:\[)?(?<time>\d{1,2}:\d{2}(?::\d{2})?)(?:\])?\s*(?:-|:|\s)\s*(?<title>.+?)\s*$")
            if ($match.Success) {
                Add-Chapter -Rows $rows -Seen $seen -Timecode $match.Groups["time"].Value -Title $match.Groups["title"].Value -Source "transcript markers"
            }
        }

        $body = Get-MarkdownSection -Text $TranscriptText -Heading "Transcript"
        foreach ($line in ($body -split "\r?\n")) {
            $match = [regex]::Match($line, "^\s*#{1,6}\s*(?:\[)?(?<time>\d{1,2}:\d{2}(?::\d{2})?)(?:\])?\s*(?:-|:)\s*(?<title>.+?)\s*$")
            if ($match.Success) {
                Add-Chapter -Rows $rows -Seen $seen -Timecode $match.Groups["time"].Value -Title $match.Groups["title"].Value -Source "transcript heading"
            }
        }
    }

    $liveNotes = @(Get-LiveNoteRows -ProductionText $ProductionText)
    foreach ($note in $liveNotes) {
        $haystack = "$($note.Note) $($note.Action)"
        if ($rows.Count -eq 0 -or $haystack -match "(?i)\b(chapter|section|segment|open|close|story|segue)\b") {
            $title = if (-not [string]::IsNullOrWhiteSpace($note.Action)) { $note.Action } else { $note.Note }
            Add-Chapter -Rows $rows -Seen $seen -Timecode $note.Timecode -Title $title -Source "live notes"
        }
    }

    if ($rows.Count -eq 0) {
        Add-Chapter -Rows $rows -Seen $seen -Timecode "00:00" -Title "Opening" -Source "default"
    }

    return $rows.ToArray()
}

function Add-Clip {
    param(
        [System.Collections.Generic.List[object]]$Rows,
        [hashtable]$Seen,
        [string]$Priority,
        [string]$Timecode,
        [string]$Hook,
        [string]$Source,
        [string]$Status = "Needs review"
    )

    if ([string]::IsNullOrWhiteSpace($Hook)) {
        return
    }

    $time = if ([string]::IsNullOrWhiteSpace($Timecode)) { "" } else { Normalize-Timecode -Value $Timecode }
    $cleanHook = ($Hook -replace "\s+", " ").Trim(" ", "-", ":", "|")
    if ([string]::IsNullOrWhiteSpace($cleanHook) -or $cleanHook -match "^(?i)tbd\b") {
        return
    }

    $key = "$time|$cleanHook"
    if ($Seen.ContainsKey($key)) {
        return
    }

    $Seen[$key] = $true
    $Rows.Add([ordered]@{
        Priority = $Priority
        Timecode = $time
        Hook = $cleanHook
        Source = $Source
        Status = $Status
    })
}

function Get-Clips {
    param(
        [string]$TranscriptText,
        [string]$ProductionText
    )

    $rows = New-Object System.Collections.Generic.List[object]
    $seen = @{}

    foreach ($moment in (Get-Bullets -Text $ProductionText -Heading "Best Moments")) {
        $match = [regex]::Match($moment, "^(?<time>\d{1,2}:\d{2}(?::\d{2})?)\s*(?:-|:)\s*(?<hook>.+)$")
        if ($match.Success) {
            Add-Clip -Rows $rows -Seen $seen -Priority "P1" -Timecode $match.Groups["time"].Value -Hook $match.Groups["hook"].Value -Source "best moments"
        }
        else {
            Add-Clip -Rows $rows -Seen $seen -Priority "P1" -Timecode "" -Hook $moment -Source "best moments"
        }
    }

    foreach ($note in (Get-LiveNoteRows -ProductionText $ProductionText)) {
        $haystack = "$($note.Note) $($note.Action)"
        if ($haystack -match "(?i)\b(clip|short|pull|highlight|best|good moment|funny|quote)\b") {
            $hook = if (-not [string]::IsNullOrWhiteSpace($note.Action)) { $note.Action } else { $note.Note }
            Add-Clip -Rows $rows -Seen $seen -Priority "P1" -Timecode $note.Timecode -Hook $hook -Source "live notes"
        }
    }

    if (Test-TranscriptContent -TranscriptText $TranscriptText) {
        $body = Get-MarkdownSection -Text $TranscriptText -Heading "Transcript"
        foreach ($line in ($body -split "\r?\n")) {
            if ($line -notmatch "(?i)(\[clip\]|\[highlight\]|clip:|highlight:)") {
                continue
            }

            $time = ""
            $hook = $line
            $match = [regex]::Match($line, "^\s*(?:\[)?(?<time>\d{1,2}:\d{2}(?::\d{2})?)(?:\])?\s*(?:-|:)?\s*(?<hook>.+)$")
            if ($match.Success) {
                $time = $match.Groups["time"].Value
                $hook = $match.Groups["hook"].Value
            }

            $hook = ($hook -replace "(?i)\[clip\]|\[highlight\]|clip:|highlight:", "").Trim()
            Add-Clip -Rows $rows -Seen $seen -Priority "P2" -Timecode $time -Hook $hook -Source "transcript marker"
        }
    }

    return $rows.ToArray()
}

function Get-CutList {
    param([string]$ProductionText)

    $rows = New-Object System.Collections.Generic.List[object]

    foreach ($note in (Get-LiveNoteRows -ProductionText $ProductionText)) {
        $haystack = "$($note.Note) $($note.Action)"
        if ($haystack -match "(?i)\b(cut|remove|fix|trim|confusing|awkward|restart|mistake|repeat)\b") {
            $rows.Add([ordered]@{
                Timecode = $note.Timecode
                Issue = $note.Note
                Action = if ($note.Action) { $note.Action } else { "Review for edit" }
                Source = "live notes"
            })
        }
    }

    foreach ($spot in (Get-Bullets -Text $ProductionText -Heading "Confusing Spots")) {
        $rows.Add([ordered]@{
            Timecode = ""
            Issue = $spot
            Action = "Clarify, tighten, or cut"
            Source = "confusing spots"
        })
    }

    return $rows.ToArray()
}

function ConvertTo-MarkdownTable {
    param(
        [object[]]$Rows,
        [string[]]$Headers,
        [string]$EmptyLine
    )

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("| $($Headers -join " | ") |")
    $lines.Add("| $(($Headers | ForEach-Object { "---" }) -join " | ") |")

    if ($Rows.Count -eq 0) {
        $lines.Add($EmptyLine)
        return ($lines -join "`n")
    }

    foreach ($row in $Rows) {
        $cells = foreach ($header in $Headers) {
            $value = Get-RowValue -Row $row -Name $header
            if ([string]::IsNullOrWhiteSpace($value)) { "-" } else { ($value -replace "\|", "\|") -replace "\r?\n", " " }
        }
        $lines.Add("| $($cells -join " | ") |")
    }

    return ($lines -join "`n")
}

function Get-RowValue {
    param(
        [object]$Row,
        [string]$Name
    )

    if ($Row -is [System.Collections.IDictionary] -and $Row.Contains($Name)) {
        return [string]$Row[$Name]
    }

    $property = $Row.PSObject.Properties[$Name]
    if ($property) {
        return [string]$property.Value
    }

    return ""
}

function ConvertTo-CsvCell {
    param([string]$Value)

    if ($null -eq $Value) {
        $Value = ""
    }

    return '"' + ($Value -replace '"', '""') + '"'
}

function ConvertTo-CsvText {
    param(
        [object[]]$Rows,
        [string[]]$Headers
    )

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add(($Headers | ForEach-Object { ConvertTo-CsvCell $_ }) -join ",")

    foreach ($row in $Rows) {
        $cells = foreach ($header in $Headers) {
            $value = Get-RowValue -Row $row -Name $header
            ConvertTo-CsvCell $value
        }
        $lines.Add($cells -join ",")
    }

    return ($lines -join "`n")
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
$productionText = Get-TextOrEmpty -Path (Join-Path $episodeDir "production-notes.md")
$publishingText = Get-TextOrEmpty -Path (Join-Path $episodeDir "publishing.md")
$transcriptText = Get-TextOrEmpty -Path (Join-Path $episodeDir "transcript.md")

if ([string]::IsNullOrWhiteSpace($episodeText)) {
    throw "Missing or empty episode.md in $episodeDir"
}

$headingMatch = [regex]::Match($episodeText, "(?m)^#\s+Episode\s+(?<number>\d{3})\s*:\s*(?<label>.+?)\s*$")
$metadata = Get-MarkdownSection -Text $episodeText -Heading "Metadata"
$number = Get-FirstValue @((Get-ListField -Text $metadata -Name "Number"), $headingMatch.Groups["number"].Value)
$label = Get-FirstValue @((Get-ListField -Text $metadata -Name "Label"), $headingMatch.Groups["label"].Value, $episodeName)
$angle = Get-MarkdownSection -Text $episodeText -Heading "Working Angle"
$recordingSetup = Get-MarkdownSection -Text $productionText -Heading "Recording Setup"
$mediaFolder = Get-FirstValue @((Get-ListField -Text $recordingSetup -Name "Media folder"), "Reel It In Media/$episodeName/")
$descriptProject = Get-FirstValue @((Get-ListField -Text (Get-MarkdownSection -Text $transcriptText -Heading "Source") -Name "Descript project"))
$transcriptStatus = Get-TranscriptStatus -TranscriptText $transcriptText
$chapters = @(Get-Chapters -TranscriptText $transcriptText -ProductionText $productionText)
$clips = @(Get-Clips -TranscriptText $transcriptText -ProductionText $productionText)
$cutList = @(Get-CutList -ProductionText $productionText)
$bestMoments = @(Get-Bullets -Text $productionText -Heading "Best Moments")
$editDecisions = @(Get-Bullets -Text $productionText -Heading "Edit Decisions")
$finalTitle = Get-FirstValue @((Get-ListField -Text (Get-MarkdownSection -Text $publishingText -Heading "Final Metadata") -Name "Final title"), "Reel It In ${number}: $label")

if ([string]::IsNullOrWhiteSpace($OutputPath)) {
    $OutputPath = Join-Path $episodeDir "edit-plan.md"
}
elseif (-not [System.IO.Path]::IsPathRooted($OutputPath)) {
    $OutputPath = Join-Path $repoRoot $OutputPath
}

$jsonPath = [System.IO.Path]::ChangeExtension($OutputPath, ".json")
$handoffDir = Join-Path $episodeDir "handoff"
$editorDir = Join-Path $handoffDir "editor"
$handoffEditPlanPath = Join-Path $handoffDir "edit-plan.md"
$chapterCsvPath = Join-Path $editorDir "chapters.csv"
$clipCsvPath = Join-Path $editorDir "clip-candidates.csv"
$cleanupChecklistPath = Join-Path $editorDir "transcript-cleanup-checklist.md"

$chapterTable = ConvertTo-MarkdownTable -Rows $chapters -Headers @("Timecode", "Title", "Source") -EmptyLine "| 00:00 | Opening | default |"
$clipTable = ConvertTo-MarkdownTable -Rows $clips -Headers @("Priority", "Timecode", "Hook", "Source", "Status") -EmptyLine "| - | - | No marked clips yet. Add best moments in production notes or transcript markers. | - | - |"
$cutTable = ConvertTo-MarkdownTable -Rows $cutList -Headers @("Timecode", "Issue", "Action", "Source") -EmptyLine "| - | No cut list items yet. | Review after transcript pass. | - |"
$bestBlock = if ($bestMoments.Count -gt 0) { ($bestMoments | ForEach-Object { "- $_" }) -join "`n" } else { "- No best moments logged yet." }
$editDecisionBlock = if ($editDecisions.Count -gt 0) { ($editDecisions | ForEach-Object { "- $_" }) -join "`n" } else { "- No edit decisions logged yet." }

$nextActions = New-Object System.Collections.Generic.List[string]
if ($transcriptStatus -ne "Transcript ready for edit planning") {
    $nextActions.Add("Export the Descript transcript into `episodes/$episodeName/transcript.md` or paste a transcript link.")
    $nextActions.Add("Add rough timestamps to `production-notes.md` while the recording is still fresh.")
}
else {
    $nextActions.Add("Check transcript speaker labels for Shane and Dad.")
    $nextActions.Add("Promote final chapter rows into `publishing.md` after the edit is locked.")
}
$nextActions.Add("Fill runtime and final export paths after Descript and Auphonic exports are done.")
$nextActionBlock = ($nextActions | ForEach-Object { "- $_" }) -join "`n"

$cleanupChecklistItems = @"
- [ ] Speaker labels are consistently Shane and Dad.
- [ ] AI product names and company names are spelled correctly.
- [ ] Source names match ``sources.md``.
- [ ] Any strong claim is either sourced, softened, or cut.
- [ ] Chapter timecodes match the final edit.
- [ ] Clip candidates have usable start points and hooks.
- [ ] Filler removal did not flatten Dad's natural questions.
- [ ] Runtime is copied into ``publishing.md``.
"@

$cleanupChecklist = @"
# Transcript Cleanup Checklist

Generated by ``tools/generate-edit-plan.ps1`` from ``$episodeName``.

$cleanupChecklistItems
"@

$content = @"
# Edit Plan

Generated by ``tools/generate-edit-plan.ps1`` from ``$episodeName``.

## Episode

- Title: $finalTitle
- Episode number: $number
- Label: $label
- Transcript status: $transcriptStatus
- Descript project: $descriptProject
- Media folder: $mediaFolder

## Edit Goal

$(Format-Section $angle)

## Assembly Pass

- Preserve the father-son conversation and Dad's genuine "why does that matter?" energy.
- Cut dead air, source lookup pauses, false starts, repeated explanations, and setup chatter.
- Keep the three-story shape clear enough that a tired listener can follow it.
- If a claim is not supported by ``sources.md``, soften it or cut it.
- Keep sparks as doors into conversation, not lectures.

## Chapters

$chapterTable

## Keep List

$bestBlock

## Cut Or Repair List

$cutTable

## Clip Candidates

$clipTable

## Edit Decisions

$editDecisionBlock

## Transcript Cleanup

$cleanupChecklistItems

## Next Actions

$nextActionBlock
"@

$metadataObject = [ordered]@{
    schemaVersion = 1
    generatedAt = (Get-Date).ToString("s")
    episode = [ordered]@{
        folder = $episodeName
        number = $number
        label = $label
        title = $finalTitle
    }
    inputs = [ordered]@{
        mediaFolder = $mediaFolder
        transcriptStatus = $transcriptStatus
        descriptProject = $descriptProject
        productionNotes = "episodes/$episodeName/production-notes.md"
        transcript = "episodes/$episodeName/transcript.md"
        sources = "episodes/$episodeName/sources.md"
    }
    chapters = $chapters
    clips = $clips
    cutList = $cutList
    bestMoments = $bestMoments
    editDecisions = $editDecisions
    nextActions = $nextActions.ToArray()
}

$generatedMarker = 'Generated by `tools/generate-edit-plan.ps1`'
$existingEditPlan = Get-TextOrEmpty -Path $OutputPath
$isGenerated = $existingEditPlan.Contains($generatedMarker)

if ((Test-Path -LiteralPath $OutputPath) -and -not $Force -and -not $isGenerated -and -not [string]::IsNullOrWhiteSpace($existingEditPlan)) {
    Write-Warning "Existing edit plan has manual content. Re-run with -Force to replace it."
    Write-Host "Target: $OutputPath"
    exit 2
}

if ($PSCmdlet.ShouldProcess($OutputPath, "Write edit plan and editor artifacts")) {
    New-Item -ItemType Directory -Force -Path $handoffDir | Out-Null
    New-Item -ItemType Directory -Force -Path $editorDir | Out-Null
    Write-Utf8Text -Path $OutputPath -Content $content
    Write-Utf8Json -Path $jsonPath -Data $metadataObject
    Write-Utf8Text -Path $handoffEditPlanPath -Content $content
    Write-Utf8Text -Path $chapterCsvPath -Content (ConvertTo-CsvText -Rows $chapters -Headers @("Timecode", "Title", "Source"))
    Write-Utf8Text -Path $clipCsvPath -Content (ConvertTo-CsvText -Rows $clips -Headers @("Priority", "Timecode", "Hook", "Source", "Status"))
    Write-Utf8Text -Path $cleanupChecklistPath -Content $cleanupChecklist
}

Write-Host "Edit plan written: $OutputPath"
Write-Host "Editor handoff:    $handoffEditPlanPath"
Write-Host "Editor CSV folder: $editorDir"
Write-Host "Transcript status: $transcriptStatus"
Write-Host "Chapters: $($chapters.Count)"
Write-Host "Clip candidates: $($clips.Count)"
