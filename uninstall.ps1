# Skill Router Uninstaller for Windows
# Run: powershell -ExecutionPolicy Bypass -File uninstall.ps1

$ErrorActionPreference = "SilentlyContinue"

$CLAUDE_DIR = "$env:USERPROFILE\.claude"

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "Uninstalling Skill Router..." -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

# Remove files
Remove-Item "$CLAUDE_DIR\CLAUDE.md" -Force -ErrorAction SilentlyContinue
Remove-Item "$CLAUDE_DIR\skill-catalog.yaml" -Force -ErrorAction SilentlyContinue
Remove-Item "$CLAUDE_DIR\hooks\user-prompt-submit.ps1" -Force -ErrorAction SilentlyContinue
Remove-Item "$CLAUDE_DIR\bin\regenerate-catalog.ps1" -Force -ErrorAction SilentlyContinue
Remove-Item "$CLAUDE_DIR\bin\update-project-profile.ps1" -Force -ErrorAction SilentlyContinue
Remove-Item "$CLAUDE_DIR\projects" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "  Removed Skill Router files" -ForegroundColor Green

# Remove aliases from PowerShell profile
$PROFILE_PATH = $PROFILE.CurrentUserAllHosts
if (Test-Path $PROFILE_PATH) {
    $content = Get-Content $PROFILE_PATH -Raw
    if ($content -match "# Skill Router aliases") {
        # Remove the aliases block
        $newContent = $content -replace '(?s)\r?\n# Skill Router aliases.*?function claude-update-project \{[^}]+\}', ''
        Set-Content -Path $PROFILE_PATH -Value $newContent.Trim()
        Write-Host "  Removed aliases from PowerShell profile" -ForegroundColor Green
    }
}

# Remove hook from settings.json
$SETTINGS_FILE = "$CLAUDE_DIR\settings.json"
if (Test-Path $SETTINGS_FILE) {
    $content = Get-Content $SETTINGS_FILE -Raw
    if ($content -match "user-prompt-submit\.(sh|ps1)") {
        try {
            $settings = Get-Content $SETTINGS_FILE | ConvertFrom-Json
            if ($settings.hooks -and $settings.hooks.UserPromptSubmit) {
                # Filter out hooks containing user-prompt-submit
                $settings.hooks.UserPromptSubmit = @($settings.hooks.UserPromptSubmit | Where-Object {
                    $dominated = $false
                    foreach ($hook in $_.hooks) {
                        if ($hook.command -match "user-prompt-submit") {
                            $dominated = $true
                            break
                        }
                    }
                    -not $dominated
                })
                $settings | ConvertTo-Json -Depth 10 | Set-Content $SETTINGS_FILE
                Write-Host "  Removed hook from settings.json" -ForegroundColor Green
            }
        } catch {
            Write-Host "  Could not update settings.json - please remove hook manually" -ForegroundColor Yellow
        }
    }
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "  Skill Router uninstalled" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""
