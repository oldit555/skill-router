# update-project-profile.ps1 - Clears project cache to force fresh analysis
# Usage: update-project-profile.ps1 [project_dir]
#
# This script deletes the project cache, forcing Sonnet to do a full
# cold start analysis on the next session.

param(
    [string]$ProjectDir = "."
)

$ErrorActionPreference = "Stop"

$ProjectDir = (Resolve-Path $ProjectDir).Path
$ProjectName = Split-Path -Leaf $ProjectDir
$CacheDir = "$env:USERPROFILE\.claude\projects"
$CacheFile = "$CacheDir\$ProjectName.cache.yaml"

Write-Host "Project: $ProjectName"
Write-Host "Path: $ProjectDir"
Write-Host ""

if (Test-Path $CacheFile) {
    Remove-Item $CacheFile -Force
    Write-Host "Cache cleared: $CacheFile"
    Write-Host "Next session will do full analysis (cold start)."
} else {
    Write-Host "No cache found. Next session will do full analysis."
}

Write-Host ""
