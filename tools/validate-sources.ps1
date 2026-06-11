[CmdletBinding()]
param(
    [string]$Path = "",
    [int]$TimeoutSec = 15
)

$ErrorActionPreference = "Stop"

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")

if ([string]::IsNullOrWhiteSpace($Path)) {
    $targetPath = Join-Path $repoRoot "episodes"
}
elseif (Test-Path -LiteralPath $Path) {
    $targetPath = Resolve-Path -LiteralPath $Path
}
else {
    $episodePath = Join-Path (Join-Path $repoRoot "episodes") $Path
    if (Test-Path -LiteralPath $episodePath) {
        $targetPath = Resolve-Path -LiteralPath $episodePath
    }
    else {
        throw "Path not found: $Path"
    }
}

$targetItem = Get-Item -LiteralPath $targetPath
if ($targetItem.PSIsContainer) {
    $files = Get-ChildItem -LiteralPath $targetItem.FullName -Recurse -File -Filter "*.md" |
        Where-Object { $_.Name -notin @("automation-report.md", "research-scout.md", "research-inbox.md", "research-drafts.md") -and $_.FullName -notmatch "[\\/]handoff[\\/]" }
}
else {
    $files = @($targetItem)
}

$urlPattern = 'https?://[^\s<>\)\]"]+'
$trimChars = @('.', ',', ';', ':', ')', ']', '"', "'")
$cache = @{}
$results = New-Object System.Collections.Generic.List[object]
$userAgent = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0 Safari/537.36"
$ignoredUrlPatterns = @(
    '^https://fonts\.googleapis\.com/?$',
    '^https://fonts\.gstatic\.com/?$',
    '^http://www\.w3\.org/2000/svg$'
)

function Test-SourceUrl {
    param(
        [string]$Url,
        [int]$Timeout
    )

    try {
        $response = Invoke-WebRequest -Uri $Url -Method Head -MaximumRedirection 5 -TimeoutSec $Timeout -UserAgent $userAgent -UseBasicParsing -ErrorAction Stop
        return [pscustomobject]@{
            StatusCode = [int]$response.StatusCode
            Result = "OK"
            Detail = "HEAD"
        }
    }
    catch {
        $headError = $_.Exception.Message

        try {
            $response = Invoke-WebRequest -Uri $Url -Method Get -MaximumRedirection 5 -TimeoutSec $Timeout -UserAgent $userAgent -UseBasicParsing -ErrorAction Stop
            return [pscustomobject]@{
                StatusCode = [int]$response.StatusCode
                Result = "OK"
                Detail = "GET fallback"
            }
        }
        catch {
            $statusCode = 0
            if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
                $statusCode = [int]$_.Exception.Response.StatusCode
            }

            if ($statusCode -in @(401, 403, 429)) {
                return [pscustomobject]@{
                    StatusCode = $statusCode
                    Result = "WARN"
                    Detail = "Checker was blocked or rate-limited. Manually verify in browser. HEAD: $headError; GET: $($_.Exception.Message)"
                }
            }

            return [pscustomobject]@{
                StatusCode = $statusCode
                Result = "FAIL"
                Detail = "HEAD: $headError; GET: $($_.Exception.Message)"
            }
        }
    }
}

foreach ($file in $files) {
    $lineNumber = 0
    foreach ($line in Get-Content -LiteralPath $file.FullName) {
        $lineNumber++
        $matches = [regex]::Matches($line, $urlPattern)

        foreach ($match in $matches) {
            $url = $match.Value.TrimEnd($trimChars)
            if ([string]::IsNullOrWhiteSpace($url)) {
                continue
            }
            $ignore = $false
            foreach ($ignoredPattern in $ignoredUrlPatterns) {
                if ($url -match $ignoredPattern) {
                    $ignore = $true
                    break
                }
            }
            if ($ignore) {
                continue
            }

            if (-not $cache.ContainsKey($url)) {
                $cache[$url] = Test-SourceUrl -Url $url -Timeout $TimeoutSec
            }

            $check = $cache[$url]
            $results.Add([pscustomobject]@{
                File = $file.FullName.Replace("$repoRoot\", "")
                Line = $lineNumber
                Status = $check.Result
                Code = $check.StatusCode
                Url = $url
                Detail = $check.Detail
            })
        }
    }
}

if ($results.Count -eq 0) {
    Write-Host "No source URLs found under $targetPath"
    exit 0
}

$results | Sort-Object Status, File, Line | Format-Table File, Line, Status, Code, Url -AutoSize

$warnings = @($results | Where-Object { $_.Status -eq "WARN" })
$failed = @($results | Where-Object { $_.Status -eq "FAIL" })

if ($warnings.Count -gt 0) {
    Write-Host ""
    Write-Host "Warnings requiring manual browser check:"
    $warnings | Format-List File, Line, Url, Code, Detail
}

if ($failed.Count -gt 0) {
    Write-Host ""
    Write-Host "Failed source checks:"
    $failed | Format-List File, Line, Url, Code, Detail
    exit 1
}

Write-Host ""
if ($warnings.Count -gt 0) {
    Write-Host "Checked $($results.Count) source reference(s); $($warnings.Count) warning(s), no hard failures."
}
else {
    Write-Host "Checked $($results.Count) source reference(s); all reachable."
}
