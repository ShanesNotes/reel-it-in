[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$Episode = "",
    [string]$MediaRoot = "",
    [string]$RecordingUrl = "",
    [switch]$NoOpen,
    [switch]$SkipPipeline,
    [switch]$FullCheck,
    [switch]$OpenObs
)

$ErrorActionPreference = "Stop"

Import-Module (Join-Path $PSScriptRoot "Modules/ReelItIn.Tools.psm1") -Force

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$episodesDir = Join-Path $repoRoot "episodes"

function Get-TextOrEmpty {
    param([string]$Path)

    if (Test-Path -LiteralPath $Path) {
        return Get-Content -LiteralPath $Path -Raw
    }

    return ""
}

function Test-WebUrl {
    param([string]$Value)

    return $Value -match '^https?://'
}

function Add-Line {
    param(
        [System.Collections.Generic.List[string]]$Lines,
        [string]$Value = ""
    )

    $Lines.Add($Value)
}

function Invoke-OpenTarget {
    param(
        [string]$Label,
        [string]$Target,
        [System.Collections.Generic.List[string]]$Opened,
        [System.Collections.Generic.List[string]]$Warnings
    )

    if ([string]::IsNullOrWhiteSpace($Target)) {
        $Warnings.Add("$Label target is empty.")
        return
    }

    try {
        Start-Process -FilePath $Target | Out-Null
        $Opened.Add("${Label}: $Target")
    }
    catch {
        $Warnings.Add("Could not open $Label ($Target): $($_.Exception.Message)")
    }
}

function Find-ObsPath {
    if ([System.Environment]::OSVersion.Platform -ne [System.PlatformID]::Win32NT) {
        return ""
    }

    $candidates = @()
    if ($env:ProgramFiles) {
        $candidates += (Join-Path $env:ProgramFiles "obs-studio\bin\64bit\obs64.exe")
    }
    if (${env:ProgramFiles(x86)}) {
        $candidates += (Join-Path ${env:ProgramFiles(x86)} "obs-studio\bin\64bit\obs64.exe")
    }

    foreach ($candidate in $candidates) {
        if (Test-Path -LiteralPath $candidate) {
            return $candidate
        }
    }

    return ""
}

$episodeDir = Resolve-ReelItInEpisodeDirectory -EpisodesDir $episodesDir -Value $Episode
$episodeName = Split-Path -Path $episodeDir -Leaf
$handoffDir = Join-Path $episodeDir "handoff"
$dashboardPath = Join-Path (Join-Path $repoRoot "app") "reel-it-in.html"
$productionNotesPath = Join-Path $episodeDir "production-notes.md"
$recordingPacketPath = Join-Path $handoffDir "recording-packet.md"
$dadPacketPath = Join-Path $handoffDir "dad-packet.md"
$sessionLaunchPath = Join-Path $handoffDir "session-launch.md"
$opened = New-Object System.Collections.Generic.List[string]
$warnings = New-Object System.Collections.Generic.List[string]

if (-not $SkipPipeline) {
    $powerShellExe = Resolve-ReelItInPowerShellExecutable -RetryCommand "pwsh -NoProfile -File ./tools/start-recording-session.ps1 -Episode $episodeName -NoOpen"
    $pipelineScriptPath = Join-Path $PSScriptRoot "run-episode-pipeline.ps1"
    if (-not (Test-Path -LiteralPath $pipelineScriptPath)) {
        throw "Recording session preflight failed. Missing pipeline script: $pipelineScriptPath"
    }

    $pipelineArgs = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $pipelineScriptPath, "-Episode", $episodeName, "-UpdateDashboard", "-SkipResearchFeeds")
    if (-not $FullCheck) {
        $pipelineArgs += "-SkipSourceValidation"
    }

    & $powerShellExe @pipelineArgs
    if ($LASTEXITCODE -ne 0) {
        throw "Recording session pipeline failed. Run tools/run-episode-pipeline.ps1 for details."
    }
}

$episodeText = Get-TextOrEmpty -Path (Join-Path $episodeDir "episode.md")
$dadText = Get-TextOrEmpty -Path (Join-Path $episodeDir "dad-brief.md")
$productionText = Get-TextOrEmpty -Path $productionNotesPath
$metadata = Get-ReelItInMarkdownSection -Text $episodeText -Heading "Metadata"
$dadRecording = Get-ReelItInMarkdownSection -Text $dadText -Heading "Recording"
$productionSetup = Get-ReelItInMarkdownSection -Text $productionText -Heading "Recording Setup"

if ([string]::IsNullOrWhiteSpace($RecordingUrl)) {
    $RecordingUrl = Get-ReelItInListField -Text $dadRecording -Name "Link"
}

if ([string]::IsNullOrWhiteSpace($MediaRoot)) {
    $MediaRoot = Join-Path ([Environment]::GetFolderPath("MyDocuments")) "Reel It In Media"
}

$episodeMediaDir = Join-Path $MediaRoot $episodeName
$mediaDirs = @(
    $episodeMediaDir,
    (Join-Path $episodeMediaDir "raw"),
    (Join-Path $episodeMediaDir "exports"),
    (Join-Path $episodeMediaDir "clips"),
    (Join-Path $episodeMediaDir "thumbnails"),
    (Join-Path $episodeMediaDir "transcripts")
)

if ($PSCmdlet.ShouldProcess($episodeMediaDir, "Create recording media folder skeleton")) {
    foreach ($dir in $mediaDirs) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
}

$setupFields = @("Recording service", "Backup recording", "Microphones", "Camera", "Headphones", "Media folder")
$missingSetup = New-Object System.Collections.Generic.List[string]
foreach ($field in $setupFields) {
    $value = Get-ReelItInListField -Text $productionSetup -Name $field
    if ([string]::IsNullOrWhiteSpace($value)) {
        $missingSetup.Add($field)
    }
}

if (-not (Test-WebUrl $RecordingUrl)) {
    $warnings.Add("Recording link is not set. Add it to dad-brief.md or pass -RecordingUrl.")
}

if (-not $NoOpen) {
    Invoke-OpenTarget -Label "Dashboard" -Target $dashboardPath -Opened $opened -Warnings $warnings
    Invoke-OpenTarget -Label "Production notes" -Target $productionNotesPath -Opened $opened -Warnings $warnings
    Invoke-OpenTarget -Label "Recording packet" -Target $recordingPacketPath -Opened $opened -Warnings $warnings
    Invoke-OpenTarget -Label "Dad packet" -Target $dadPacketPath -Opened $opened -Warnings $warnings
    Invoke-OpenTarget -Label "Media folder" -Target $episodeMediaDir -Opened $opened -Warnings $warnings

    if (Test-WebUrl $RecordingUrl) {
        Invoke-OpenTarget -Label "Recording room" -Target $RecordingUrl -Opened $opened -Warnings $warnings
    }

    if ($OpenObs) {
        $obsPath = Find-ObsPath
        if ($obsPath) {
            try {
                Start-Process -FilePath $obsPath -WorkingDirectory (Split-Path -Path $obsPath -Parent) | Out-Null
                $opened.Add("OBS: $obsPath")
            }
            catch {
                $warnings.Add("Could not open OBS ($obsPath): $($_.Exception.Message)")
            }
        }
        else {
            $warnings.Add("OBS was requested, but obs64.exe was not found in the standard install paths.")
        }
    }
}

New-Item -ItemType Directory -Force -Path $handoffDir | Out-Null
$generatedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$episodeLabel = Get-ReelItInListField -Text $metadata -Name "Label"
if ([string]::IsNullOrWhiteSpace($episodeLabel)) {
    $episodeLabel = $episodeName
}

$lines = New-Object System.Collections.Generic.List[string]
Add-Line $lines "# Recording Session Launch"
Add-Line $lines ""
Add-Line $lines "Generated by ``tools/start-recording-session.ps1`` from ``$episodeName``."
Add-Line $lines ""
Add-Line $lines "## Session"
Add-Line $lines ""
Add-Line $lines "- Episode: $episodeName"
Add-Line $lines "- Label: $episodeLabel"
Add-Line $lines "- Generated: $generatedAt"
Add-Line $lines "- Opened targets: $(if ($NoOpen) { 'No; -NoOpen was used.' } else { 'Yes.' })"
Add-Line $lines "- Pipeline run: $(if ($SkipPipeline) { 'Skipped.' } elseif ($FullCheck) { 'Full check with source validation.' } else { 'Fast recording sync; source validation skipped.' })"
Add-Line $lines ""
Add-Line $lines "## Core Files"
Add-Line $lines ""
Add-Line $lines "- Dashboard: ``$dashboardPath``"
Add-Line $lines "- Production notes: ``$productionNotesPath``"
Add-Line $lines "- Recording packet: ``$recordingPacketPath``"
Add-Line $lines "- Dad packet: ``$dadPacketPath``"
Add-Line $lines "- Automation report: ``$(Join-Path $episodeDir 'automation-report.md')``"
Add-Line $lines ""
Add-Line $lines "## Media Folders"
Add-Line $lines ""
foreach ($dir in $mediaDirs) {
    Add-Line $lines "- ``$dir``"
}
Add-Line $lines ""
Add-Line $lines "## Recording Room"
Add-Line $lines ""
Add-Line $lines "- Recording URL: $(if (Test-WebUrl $RecordingUrl) { $RecordingUrl } else { 'TBD' })"
Add-Line $lines ""
Add-Line $lines "## Opened"
Add-Line $lines ""
if ($opened.Count -eq 0) {
    Add-Line $lines "- None."
}
else {
    foreach ($item in $opened) {
        Add-Line $lines "- $item"
    }
}
Add-Line $lines ""
Add-Line $lines "## Missing Before Recording"
Add-Line $lines ""
if ($warnings.Count -eq 0 -and $missingSetup.Count -eq 0) {
    Add-Line $lines "- Nothing detected by the launcher."
}
else {
    foreach ($warning in $warnings) {
        Add-Line $lines "- $warning"
    }
    foreach ($field in $missingSetup) {
        Add-Line $lines "- Recording setup field is blank: $field."
    }
}

Write-ReelItInUtf8Text -Path $sessionLaunchPath -Content ($lines -join "`n")

Write-Host "Recording session prepared: $episodeName"
Write-Host "Session launch report: $sessionLaunchPath"
Write-Host "Media folder: $episodeMediaDir"
if ($warnings.Count -gt 0 -or $missingSetup.Count -gt 0) {
    Write-Host "Attention items: $($warnings.Count + $missingSetup.Count)"
}
else {
    Write-Host "Attention items: 0"
}
