function Resolve-ReelItInEpisodeDirectory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$EpisodesDir,
        [string]$Value = ""
    )

    if (-not (Test-Path -LiteralPath $EpisodesDir)) {
        throw "Episodes directory not found: $EpisodesDir"
    }

    if (-not [string]::IsNullOrWhiteSpace($Value)) {
        if (Test-Path -LiteralPath $Value) {
            return (Resolve-Path -LiteralPath $Value).Path
        }

        $candidate = Join-Path $EpisodesDir $Value
        if (Test-Path -LiteralPath $candidate) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }

        throw "Episode folder not found: $Value"
    }

    $latest = Get-ChildItem -LiteralPath $EpisodesDir -Directory |
        Where-Object { $_.Name -match "^\d{3}" } |
        Sort-Object Name |
        Select-Object -Last 1

    if (-not $latest) {
        throw "No numbered episode folders found under $EpisodesDir"
    }

    return $latest.FullName
}

function Join-ReelItInRelativePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$BasePath,
        [Parameter(Mandatory = $true)]
        [string]$RelativePath
    )

    $currentPath = $BasePath
    foreach ($part in ($RelativePath -split "[\\/]")) {
        if (-not [string]::IsNullOrWhiteSpace($part)) {
            $currentPath = Join-Path $currentPath $part
        }
    }

    return $currentPath
}

function Get-ReelItInMarkdownSection {
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

function Get-ReelItInListField {
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

function Write-ReelItInUtf8Text {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,
        [string]$Content = ""
    )

    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($Path, $Content.Trim() + [Environment]::NewLine, $utf8NoBom)
}

function Get-ReelItInMediaRoot {
    param(
        [string]$MediaRoot = ""
    )

    if (-not [string]::IsNullOrWhiteSpace($MediaRoot)) {
        return $MediaRoot
    }

    if ($IsLinux -or $IsMacOS) {
        return Join-Path $HOME "Reel It In Media"
    }

    return Join-Path ([Environment]::GetFolderPath("MyDocuments")) "Reel It In Media"
}

function Resolve-ReelItInPowerShellExecutable {
    param(
        [string]$RetryCommand = "pwsh -NoProfile -File ./tools/run-episode-pipeline.ps1 -Episode <episode-folder> -SkipSourceValidation -SkipResearchFeeds"
    )

    $candidateNames = @("pwsh")
    if ([System.Environment]::OSVersion.Platform -eq [System.PlatformID]::Win32NT) {
        $candidateNames += "powershell.exe"
    }

    foreach ($candidateName in $candidateNames) {
        $command = Get-Command $candidateName -ErrorAction SilentlyContinue
        if ($command -and $command.Source) {
            return $command.Source
        }
    }

    try {
        $currentProcess = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
        $currentName = Split-Path -Path $currentProcess -Leaf
        if ($currentProcess -and (Test-Path -LiteralPath $currentProcess) -and ($currentName -match "^(pwsh|powershell)(\.exe)?$")) {
            return $currentProcess
        }
    }
    catch {
        # Fall through to the clear preflight error below.
    }

    throw "PowerShell runtime preflight failed. Install PowerShell Core (`pwsh`) and retry: $RetryCommand"
}

Export-ModuleMember -Function @(
    "Resolve-ReelItInEpisodeDirectory",
    "Join-ReelItInRelativePath",
    "Get-ReelItInMediaRoot",
    "Get-ReelItInMarkdownSection",
    "Get-ReelItInListField",
    "Write-ReelItInUtf8Text",
    "Resolve-ReelItInPowerShellExecutable"
)
