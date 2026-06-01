[CmdletBinding()]
param(
    [string]$Episode = "",
    [switch]$UpdateDashboard,
    [switch]$SkipSourceValidation,
    [switch]$SkipResearchFeeds,
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

function Format-CommandPart {
    param([string]$Value)

    if ($Value -match "\s") {
        return '"' + ($Value -replace '"', '\"') + '"'
    }

    return $Value
}

function Format-MarkdownCell {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return "-"
    }

    return (($Value -replace "\|", "\|") -replace "\r?\n", " ").Trim()
}

function Invoke-PipelineStep {
    param(
        [string]$Name,
        [string]$FileName,
        [string[]]$Arguments,
        [string[]]$DisplayParts
    )

    $startedAt = Get-Date
    $outputText = ""
    $exitCode = 0

    try {
        $output = & $FileName @Arguments 2>&1
        if ($null -ne $LASTEXITCODE) {
            $exitCode = $LASTEXITCODE
        }
        $outputText = ($output | ForEach-Object { $_.ToString() }) -join "`n"
    }
    catch {
        $exitCode = 1
        $outputText = $_.Exception.Message
    }

    $finishedAt = Get-Date
    $command = ($DisplayParts | ForEach-Object { Format-CommandPart $_ }) -join " "
    $status = if ($exitCode -eq 0) { "PASS" } else { "FAIL" }

    return [pscustomobject]@{
        Name = $Name
        Status = $status
        ExitCode = $exitCode
        Command = $command
        StartedAt = $startedAt
        FinishedAt = $finishedAt
        DurationSec = [Math]::Round(($finishedAt - $startedAt).TotalSeconds, 1)
        Output = $outputText.Trim()
    }
}

function Invoke-ToolStep {
    param(
        [string]$Name,
        [string]$ScriptName,
        [string[]]$Arguments
    )

    $scriptPath = Join-Path $PSScriptRoot $ScriptName
    $toolArgs = @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $scriptPath) + $Arguments
    $displayParts = @(".\tools\$ScriptName") + $Arguments

    return Invoke-PipelineStep -Name $Name -FileName "powershell.exe" -Arguments $toolArgs -DisplayParts $displayParts
}

function Write-AutomationReport {
    param(
        [string]$Path,
        [string]$EpisodeName,
        [object[]]$Results,
        [bool]$HadFailure
    )

    $generatedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $resultLabel = if ($HadFailure) { "Needs attention" } else { "Ready" }
    $lines = New-Object System.Collections.Generic.List[string]

    $lines.Add("# Automation Report")
    $lines.Add("")
    $lines.Add("- Episode: $EpisodeName")
    $lines.Add("- Generated: $generatedAt")
    $lines.Add("- Result: $resultLabel")
    $lines.Add("")
    $lines.Add("## Pipeline")
    $lines.Add("")
    $lines.Add("| Step | Status | Exit | Duration | Command |")
    $lines.Add("| --- | --- | ---: | ---: | --- |")

    foreach ($result in $Results) {
        $lines.Add("| $(Format-MarkdownCell $result.Name) | $($result.Status) | $($result.ExitCode) | $($result.DurationSec)s | ``$(Format-MarkdownCell $result.Command)`` |")
    }

    $lines.Add("")
    $lines.Add("## Artifacts")
    $lines.Add("")
    $artifacts = @(
        "episode.md",
        "sources.md",
        "research-inbox.md",
        "research-inbox.json",
        "research-drafts.md",
        "research-drafts.json",
        "research-scout.md",
        "research-candidates.json",
        "dad-brief.md",
        "production-notes.md",
        "dashboard-data.js",
        "publishing.md",
        "title-thumbnail.md",
        "title-thumbnail.json",
        "thumbnail-images.json",
        "archive.json",
        "transcript.md",
        "edit-plan.md",
        "edit-plan.json",
        "handoff\session-launch.md",
        "handoff\edit-plan.md",
        "handoff\editor\chapters.csv",
        "handoff\editor\clip-candidates.csv",
        "handoff\editor\transcript-cleanup-checklist.md",
        "handoff\marketing\title-options.md",
        "handoff\marketing\thumbnail-brief.md",
        "handoff\marketing\thumbnail-prompts.txt",
        "handoff\marketing\thumbnail-board.html",
        "handoff\marketing\generated-thumbnails.md",
        "handoff\dad-packet.md",
        "handoff\recording-packet.md",
        "handoff\editor-packet.md",
        "handoff\publishing-packet.md",
        "handoff\marketing\youtube-upload.md",
        "handoff\marketing\youtube-description.txt",
        "handoff\marketing\rss-upload.md",
        "handoff\marketing\social-posts.md",
        "handoff\marketing\newsletter-blurb.md",
        "handoff\marketing\clip-candidates.csv",
        "handoff\marketing\distribution-checklist.md",
        "handoff\marketing\upload-fields.json"
    )

    foreach ($artifact in $artifacts) {
        $artifactPath = Join-Path (Split-Path -Path $Path -Parent) $artifact
        $state = if (Test-Path -LiteralPath $artifactPath) { "present" } else { "missing" }
        $lines.Add("- ``$artifact``: $state")
    }

    $lines.Add("")
    $lines.Add("## Step Output")

    foreach ($result in $Results) {
        $lines.Add("")
        $lines.Add("### $($result.Name)")
        $lines.Add("")
        $lines.Add("- Status: $($result.Status)")
        $lines.Add("- Command: ``$($result.Command)``")
        $lines.Add("")
        $lines.Add('```text')
        if ([string]::IsNullOrWhiteSpace($result.Output)) {
            $lines.Add("(no output)")
        }
        else {
            $lines.Add($result.Output)
        }
        $lines.Add('```')
    }

    Set-Content -LiteralPath $Path -Value ($lines -join "`n") -Encoding utf8
}

$episodeDir = Resolve-EpisodeDirectory -Value $Episode
$episodeName = Split-Path -Path $episodeDir -Leaf
$reportPath = Join-Path $episodeDir "automation-report.md"
$results = New-Object System.Collections.Generic.List[object]

$results.Add((Invoke-ToolStep -Name "Preflight episode status" -ScriptName "episode-status.ps1" -Arguments @("-Episode", $episodeName)))

if (-not $SkipSourceValidation) {
    $results.Add((Invoke-ToolStep -Name "Source validation" -ScriptName "validate-sources.ps1" -Arguments @("-Path", $episodeDir, "-TimeoutSec", "$TimeoutSec")))
}

if (-not $SkipResearchFeeds) {
    $results.Add((Invoke-ToolStep -Name "Collect research feeds" -ScriptName "collect-research-feeds.ps1" -Arguments @("-Episode", $episodeName)))
    $results.Add((Invoke-ToolStep -Name "Draft research candidates" -ScriptName "draft-research-candidates.ps1" -Arguments @("-Episode", $episodeName)))
}

$results.Add((Invoke-ToolStep -Name "Research scout" -ScriptName "generate-research-scout.ps1" -Arguments @("-Episode", $episodeName)))

$dashboardArgs = @("-Episode", $episodeName)
if ($UpdateDashboard) {
    $dashboardArgs += "-UpdateDashboard"
}
$results.Add((Invoke-ToolStep -Name "Dad brief" -ScriptName "generate-dad-brief.ps1" -Arguments @("-Episode", $episodeName)))
$results.Add((Invoke-ToolStep -Name "Dashboard data export" -ScriptName "export-dashboard-data.ps1" -Arguments $dashboardArgs))
$results.Add((Invoke-ToolStep -Name "Edit plan" -ScriptName "generate-edit-plan.ps1" -Arguments @("-Episode", $episodeName)))
$results.Add((Invoke-ToolStep -Name "Publishing package" -ScriptName "generate-publishing-package.ps1" -Arguments @("-Episode", $episodeName)))
$results.Add((Invoke-ToolStep -Name "Title and thumbnail package" -ScriptName "generate-title-thumbnail-package.ps1" -Arguments @("-Episode", $episodeName)))
$results.Add((Invoke-ToolStep -Name "Production packets" -ScriptName "export-production-packets.ps1" -Arguments @("-Episode", $episodeName)))
$results.Add((Invoke-ToolStep -Name "Marketing assets" -ScriptName "export-marketing-assets.ps1" -Arguments @("-Episode", $episodeName)))
$results.Add((Invoke-ToolStep -Name "Archive metadata" -ScriptName "export-archive-metadata.ps1" -Arguments @("-Episode", $episodeName, "-UpdateIndex")))
$results.Add((Invoke-ToolStep -Name "Postflight episode status" -ScriptName "episode-status.ps1" -Arguments @("-Episode", $episodeName)))
$results.Add((Invoke-PipelineStep -Name "Workspace git status" -FileName "git" -Arguments @("status", "--short") -DisplayParts @("git", "status", "--short")))

$hadFailure = @($results | Where-Object { $_.ExitCode -ne 0 }).Count -gt 0
Write-AutomationReport -Path $reportPath -EpisodeName $episodeName -Results $results.ToArray() -HadFailure $hadFailure

Write-Host "Automation report written: $reportPath"
if ($hadFailure) {
    Write-Host "Pipeline finished with one or more failed steps."
    exit 1
}

Write-Host "Pipeline finished successfully."
