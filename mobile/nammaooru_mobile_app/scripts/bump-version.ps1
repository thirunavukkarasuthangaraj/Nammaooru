param(
    [ValidateSet('patch', 'minor', 'major')]
    [string]$Part = 'patch',

    [ValidatePattern('^\d+\.\d+\.\d+$')]
    [string]$Version,

    [ValidateRange(1, 2147483647)]
    [int]$BuildNumber
)

$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$pubspecPath = Join-Path $projectRoot 'pubspec.yaml'

if (-not (Test-Path -LiteralPath $pubspecPath)) {
    throw "pubspec.yaml was not found at $pubspecPath"
}

$pubspec = Get-Content -LiteralPath $pubspecPath -Raw
$match = [regex]::Match(
    $pubspec,
    '(?m)^version:\s*(\d+)\.(\d+)\.(\d+)\+(\d+)\s*$'
)

if (-not $match.Success) {
    throw 'Expected pubspec version in the format: version: major.minor.patch+build'
}

$currentMajor = [int]$match.Groups[1].Value
$currentMinor = [int]$match.Groups[2].Value
$currentPatch = [int]$match.Groups[3].Value
$currentBuild = [int]$match.Groups[4].Value
$currentVersion = "$currentMajor.$currentMinor.$currentPatch+$currentBuild"

if ($Version) {
    $versionParts = $Version.Split('.')
    $nextMajor = [int]$versionParts[0]
    $nextMinor = [int]$versionParts[1]
    $nextPatch = [int]$versionParts[2]
} else {
    $nextMajor = $currentMajor
    $nextMinor = $currentMinor
    $nextPatch = $currentPatch

    switch ($Part) {
        'major' {
            $nextMajor++
            $nextMinor = 0
            $nextPatch = 0
        }
        'minor' {
            $nextMinor++
            $nextPatch = 0
        }
        'patch' {
            $nextPatch++
        }
    }
}

$nextBuild = if ($PSBoundParameters.ContainsKey('BuildNumber')) {
    $BuildNumber
} else {
    $currentBuild + 1
}

if ($nextBuild -le $currentBuild) {
    throw "Build number must be greater than the current build number ($currentBuild)."
}

$nextVersion = "$nextMajor.$nextMinor.$nextPatch+$nextBuild"
$updatedPubspec = $pubspec.Remove($match.Index, $match.Length).Insert(
    $match.Index,
    "version: $nextVersion"
)

[System.IO.File]::WriteAllText(
    $pubspecPath,
    $updatedPubspec,
    [System.Text.UTF8Encoding]::new($false)
)

Write-Host "Version updated: $currentVersion -> $nextVersion" -ForegroundColor Green
Write-Host 'Build the Play Store bundle with: flutter build appbundle --release'
