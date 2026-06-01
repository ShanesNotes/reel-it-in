[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [int]$Number = 0,
    [string]$Title = "",
    [string]$Slug = "",
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$episodesDir = Join-Path $repoRoot "episodes"
$templateDir = Join-Path $episodesDir "_template"

if (-not (Test-Path -LiteralPath $templateDir)) {
    throw "Missing episode template directory: $templateDir"
}

function ConvertTo-EpisodeSlug {
    param([string]$Value)

    $slug = $Value.ToLowerInvariant()
    $slug = [regex]::Replace($slug, "[^a-z0-9]+", "-")
    $slug = $slug.Trim("-")

    if ([string]::IsNullOrWhiteSpace($slug)) {
        return "untitled"
    }

    return $slug
}

if ($Number -le 0) {
    $existingNumbers = Get-ChildItem -LiteralPath $episodesDir -Directory |
        Where-Object { $_.Name -match "^\d{3}" } |
        ForEach-Object { [int]$_.Name.Substring(0, 3) }

    if ($existingNumbers) {
        $Number = (($existingNumbers | Measure-Object -Maximum).Maximum + 1)
    }
    else {
        $Number = 1
    }
}

$numberText = "{0:D3}" -f $Number

if ([string]::IsNullOrWhiteSpace($Title)) {
    $Title = "Episode $numberText"
}

if ([string]::IsNullOrWhiteSpace($Slug)) {
    $Slug = ConvertTo-EpisodeSlug $Title
}
else {
    $Slug = ConvertTo-EpisodeSlug $Slug
}

$episodeName = "$numberText-$Slug"
$episodeDir = Join-Path $episodesDir $episodeName

if ((Test-Path -LiteralPath $episodeDir) -and -not $Force) {
    throw "Episode folder already exists: $episodeDir. Use -Force to fill or replace template files."
}

if ($PSCmdlet.ShouldProcess($episodeDir, "Create episode directory")) {
    New-Item -ItemType Directory -Path $episodeDir -Force | Out-Null
}

$tokens = @{
    "EPISODE_NUMBER" = $numberText
    "EPISODE_TITLE" = $Title
    "EPISODE_SLUG" = $Slug
    "CREATED_DATE" = (Get-Date -Format "yyyy-MM-dd")
}

Get-ChildItem -LiteralPath $templateDir -File | ForEach-Object {
    $target = Join-Path $episodeDir $_.Name

    if ((Test-Path -LiteralPath $target) -and -not $Force) {
        Write-Host "Skipped existing file: $target"
        return
    }

    $content = Get-Content -LiteralPath $_.FullName -Raw
    foreach ($key in $tokens.Keys) {
        $content = $content.Replace("{{$key}}", $tokens[$key])
    }

    if ($PSCmdlet.ShouldProcess($target, "Write episode file")) {
        Set-Content -LiteralPath $target -Value $content -Encoding utf8
        Write-Host "Wrote $target"
    }
}

Write-Host "Episode workspace ready: $episodeDir"
