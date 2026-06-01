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
        return $match.Groups["value"].Value.Trim().Trim('`')
    }

    return ""
}

function Get-FirstValue {
    param([string[]]$Values)

    foreach ($value in $Values) {
        if (-not [string]::IsNullOrWhiteSpace($value) -and $value -ne "TBD") {
            return $value
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

function Write-Utf8Text {
    param(
        [string]$Path,
        [string]$Content
    )

    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($Path, $Content.Trim() + [Environment]::NewLine, $utf8NoBom)
}

$episodeDir = Resolve-EpisodeDirectory -Value $Episode
$episodeName = Split-Path -Path $episodeDir -Leaf

if ([string]::IsNullOrWhiteSpace($OutputDir)) {
    $OutputDir = Join-Path $episodeDir "handoff"
}
elseif (-not [System.IO.Path]::IsPathRooted($OutputDir)) {
    $OutputDir = Join-Path $repoRoot $OutputDir
}

$episodeText = Get-TextOrEmpty -Path (Join-Path $episodeDir "episode.md")
$dadText = Get-TextOrEmpty -Path (Join-Path $episodeDir "dad-brief.md")
$productionText = Get-TextOrEmpty -Path (Join-Path $episodeDir "production-notes.md")
$publishingText = Get-TextOrEmpty -Path (Join-Path $episodeDir "publishing.md")
$transcriptText = Get-TextOrEmpty -Path (Join-Path $episodeDir "transcript.md")
$editPlanText = Get-TextOrEmpty -Path (Join-Path $episodeDir "edit-plan.md")

if ([string]::IsNullOrWhiteSpace($episodeText)) {
    throw "Missing or empty episode.md in $episodeDir"
}

$headingMatch = [regex]::Match($episodeText, "(?m)^#\s+Episode\s+(?<number>\d{3})\s*:\s*(?<label>.+?)\s*$")
$metadata = Get-MarkdownSection -Text $episodeText -Heading "Metadata"
$number = Get-FirstValue @((Get-ListField -Text $metadata -Name "Number"), $headingMatch.Groups["number"].Value)
$label = Get-FirstValue @((Get-ListField -Text $metadata -Name "Label"), $headingMatch.Groups["label"].Value, $episodeName)
$date = Get-FirstValue @((Get-ListField -Text $metadata -Name "Date"))

$dadRecording = Get-MarkdownSection -Text $dadText -Heading "Recording"
$productionSetup = Get-MarkdownSection -Text $productionText -Heading "Recording Setup"
$recordingDate = Get-FirstValue @((Get-ListField -Text $dadRecording -Name "Date"), $date)
$recordingTime = Get-FirstValue @((Get-ListField -Text $dadRecording -Name "Time"))
$recordingLink = Get-FirstValue @((Get-ListField -Text $dadRecording -Name "Link"))
$recordingService = Get-FirstValue @((Get-ListField -Text $productionSetup -Name "Recording service"), "Riverside")
$backupRecording = Get-FirstValue @((Get-ListField -Text $productionSetup -Name "Backup recording"), "OBS safety capture if useful")
$mediaFolder = Get-FirstValue @((Get-ListField -Text $productionSetup -Name "Media folder"), "Reel It In Media/$episodeName/")

$dadPacket = @"
# Dad Packet

Generated by ``tools/export-production-packets.ps1`` from ``$episodeName``.

## Episode

- Episode: $number
- Label: $label
- Recording date: $recordingDate
- Recording time: $recordingTime
- Recording link: $recordingLink

## Theme

$(Format-Section (Get-MarkdownSection -Text $dadText -Heading "Episode Theme"))

## What We Might Talk About

$(Format-Section (Get-MarkdownSection -Text $dadText -Heading "What We Might Talk About"))

## Keep It Loose

$(Format-Section (Get-MarkdownSection -Text $dadText -Heading "Keep It Loose"))

## Avoid

$(Format-Section (Get-MarkdownSection -Text $dadText -Heading "Avoid") "-")
"@

$recordingPacket = @"
# Recording Packet

Generated by ``tools/export-production-packets.ps1`` from ``$episodeName``.

## Open Before Recording

- Dashboard: ``app/reel-it-in.html``
- Recording service: $recordingService
- Recording link: $recordingLink
- Backup recording: $backupRecording
- Notes file: ``episodes/$episodeName/production-notes.md``
- Media folder: $mediaFolder
- Session launch: ``episodes/$episodeName/handoff/session-launch.md``
- Dad packet: ``episodes/$episodeName/handoff/dad-packet.md``

## Episode Frame

$(Format-Section (Get-MarkdownSection -Text $episodeText -Heading "Working Angle"))

## Setup

$(Format-Section $productionSetup)

## Before Recording

$(Format-Section (Get-MarkdownSection -Text $productionText -Heading "Before Recording") "- Confirm audio, camera, dashboard, and recording service.")

## During Recording

$(Format-Section (Get-MarkdownSection -Text $productionText -Heading "During Recording") "- Mark covered sparks and capture rough edit notes.")

## After Recording

$(Format-Section (Get-MarkdownSection -Text $productionText -Heading "After Recording") "- Confirm uploads and save rough notes.")
"@

$editorPacket = @"
# Editor Packet

Generated by ``tools/export-production-packets.ps1`` from ``$episodeName``.

## Inputs

- Media folder: $mediaFolder
- Production notes: ``episodes/$episodeName/production-notes.md``
- Transcript: ``episodes/$episodeName/transcript.md``
- Edit plan: ``episodes/$episodeName/edit-plan.md``
- Publishing package: ``episodes/$episodeName/publishing.md``
- Sources: ``episodes/$episodeName/sources.md``

## Edit Intent

$(Format-Section (Get-MarkdownSection -Text $episodeText -Heading "Working Angle"))

## Assembly Pass

$(Format-Section (Get-MarkdownSection -Text $editPlanText -Heading "Assembly Pass") "- Generate ``edit-plan.md`` after recording notes or transcript export.")

## Chapters

$(Format-Section (Get-MarkdownSection -Text $editPlanText -Heading "Chapters") "| Timecode | Title | Source |`n| --- | --- | --- |`n| 00:00 | Opening | default |")

## Live Notes

$(Format-Section (Get-MarkdownSection -Text $productionText -Heading "Live Notes") "| Timecode | Note | Action |`n| --- | --- | --- |")

## Cut Or Repair List

$(Format-Section (Get-MarkdownSection -Text $editPlanText -Heading "Cut Or Repair List") "| Timecode | Issue | Action | Source |`n| --- | --- | --- | --- |`n| - | No cut list items yet. | Review after transcript pass. | - |")

## Best Moments

$(Format-Section (Get-AnyMarkdownSection -Text $publishingText -Heading "Best Moments") (Format-Section (Get-MarkdownSection -Text $productionText -Heading "Best Moments") "- TBD after edit."))

## Clip Candidates

$(Format-Section (Get-MarkdownSection -Text $editPlanText -Heading "Clip Candidates") "| Priority | Timecode | Hook | Source | Status |`n| --- | --- | --- | --- | --- |`n| - | - | No marked clips yet. | - | - |")

## Confusing Spots

$(Format-Section (Get-AnyMarkdownSection -Text $publishingText -Heading "Confusing Spots") (Format-Section (Get-MarkdownSection -Text $productionText -Heading "Confusing Spots") "- None logged yet."))

## Edit Decisions

$(Format-Section (Get-AnyMarkdownSection -Text $publishingText -Heading "Edit Decisions") (Format-Section (Get-MarkdownSection -Text $productionText -Heading "Edit Decisions") "- TBD after edit."))

## Transcript Status

$(if ($transcriptText -match "Paste or link the transcript here") { "Transcript has not been added yet." } elseif ([string]::IsNullOrWhiteSpace($transcriptText)) { "Transcript is missing." } else { "Transcript file exists. Check it before final publishing." })
"@

$publishingPacket = @"
# Publishing Packet

Generated by ``tools/export-production-packets.ps1`` from ``$episodeName``.

## Final Metadata

$(Format-Section (Get-MarkdownSection -Text $publishingText -Heading "Final Metadata"))

## Description

$(Format-Section (Get-MarkdownSection -Text $publishingText -Heading "Description"))

## YouTube Package

$(Format-Section (Get-MarkdownSection -Text $publishingText -Heading "YouTube Package"))

## RSS Package

$(Format-Section (Get-MarkdownSection -Text $publishingText -Heading "RSS Package"))

## Social Copy

$(Format-Section (Get-MarkdownSection -Text $publishingText -Heading "Social Copy"))

## Distribution Checklist

$(Format-Section (Get-MarkdownSection -Text $publishingText -Heading "Distribution Checklist"))
"@

if ($PSCmdlet.ShouldProcess($OutputDir, "Create production handoff packets")) {
    New-Item -ItemType Directory -Force -Path $OutputDir | Out-Null
    Write-Utf8Text -Path (Join-Path $OutputDir "dad-packet.md") -Content $dadPacket
    Write-Utf8Text -Path (Join-Path $OutputDir "recording-packet.md") -Content $recordingPacket
    Write-Utf8Text -Path (Join-Path $OutputDir "editor-packet.md") -Content $editorPacket
    Write-Utf8Text -Path (Join-Path $OutputDir "publishing-packet.md") -Content $publishingPacket
}

Write-Host "Production packets written: $OutputDir"
Write-Host "Dad packet:        dad-packet.md"
Write-Host "Recording packet:  recording-packet.md"
Write-Host "Editor packet:     editor-packet.md"
Write-Host "Publishing packet: publishing-packet.md"
