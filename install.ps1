# Skill Router Installer for Windows
# Run: powershell -ExecutionPolicy Bypass -File install.ps1

$ErrorActionPreference = "Stop"

$CLAUDE_DIR = "$env:USERPROFILE\.claude"
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

# Check if already installed
if (Test-Path "$CLAUDE_DIR\hooks\user-prompt-submit.ps1") {
    Write-Host "Skill Router is already installed." -ForegroundColor Yellow
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Reinstall will:"
    Write-Host ""
    Write-Host "  Backup (if exists):"
    Write-Host "    ~/.claude/CLAUDE.md -> CLAUDE.md.backup.{timestamp}"
    Write-Host ""
    Write-Host "  Overwrite:"
    Write-Host "    ~/.claude/CLAUDE.md"
    Write-Host "    ~/.claude/hooks/user-prompt-submit.ps1"
    Write-Host "    ~/.claude/bin/regenerate-catalog.ps1"
    Write-Host "    ~/.claude/bin/update-project-profile.ps1"
    Write-Host ""

    $response = Read-Host "Proceed with reinstall? [y/N]"
    if ($response -notmatch "^[Yy]$") {
        Write-Host "Cancelled."
        exit 0
    }
} else {
    Write-Host "Installing Skill Router..." -ForegroundColor Green
}
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan

# Create directories
New-Item -ItemType Directory -Force -Path "$CLAUDE_DIR\hooks" | Out-Null
New-Item -ItemType Directory -Force -Path "$CLAUDE_DIR\bin" | Out-Null
New-Item -ItemType Directory -Force -Path "$CLAUDE_DIR\projects" | Out-Null

# Backup existing CLAUDE.md if exists and not empty
if ((Test-Path "$CLAUDE_DIR\CLAUDE.md") -and ((Get-Item "$CLAUDE_DIR\CLAUDE.md").Length -gt 0)) {
    $lineCount = (Get-Content "$CLAUDE_DIR\CLAUDE.md" | Measure-Object -Line).Lines
    Write-Host ""
    Write-Host "Found existing CLAUDE.md ($lineCount lines)"
    $response = Read-Host "Create backup before overwriting? [Y/n]"
    if ($response -notmatch "^[Nn]$") {
        $timestamp = [int](Get-Date -UFormat %s)
        $backupFile = "$CLAUDE_DIR\CLAUDE.md.backup.$timestamp"
        Copy-Item "$CLAUDE_DIR\CLAUDE.md" $backupFile
        Write-Host "  Backed up to: $backupFile" -ForegroundColor Green
    } else {
        Write-Host "  Skipped backup" -ForegroundColor Yellow
    }
}

# Copy files
Copy-Item "$SCRIPT_DIR\files\CLAUDE.md" "$CLAUDE_DIR\CLAUDE.md" -Force
Copy-Item "$SCRIPT_DIR\files\hooks\user-prompt-submit.ps1" "$CLAUDE_DIR\hooks\" -Force
Copy-Item "$SCRIPT_DIR\files\bin\regenerate-catalog.ps1" "$CLAUDE_DIR\bin\" -Force
Copy-Item "$SCRIPT_DIR\files\bin\update-project-profile.ps1" "$CLAUDE_DIR\bin\" -Force

Write-Host "  Copied files to ~/.claude/" -ForegroundColor Green

# Update settings.json with hook config
$SETTINGS_FILE = "$CLAUDE_DIR\settings.json"
$HOOK_CONFIG = @{
    hooks = @{
        UserPromptSubmit = @(
            @{
                hooks = @(
                    @{
                        type = "command"
                        command = "powershell -ExecutionPolicy Bypass -File `"%USERPROFILE%\.claude\hooks\user-prompt-submit.ps1`""
                    }
                )
            }
        )
    }
}

if (Test-Path $SETTINGS_FILE) {
    $content = Get-Content $SETTINGS_FILE -Raw
    if ($content -match "user-prompt-submit\.(sh|ps1)") {
        Write-Host "  Hook already configured in settings.json" -ForegroundColor Green
    } else {
        # Merge hook into existing settings
        try {
            $settings = Get-Content $SETTINGS_FILE | ConvertFrom-Json
            if (-not $settings.hooks) {
                $settings | Add-Member -NotePropertyName "hooks" -NotePropertyValue @{}
            }
            if (-not $settings.hooks.UserPromptSubmit) {
                $settings.hooks | Add-Member -NotePropertyName "UserPromptSubmit" -NotePropertyValue @()
            }
            $settings.hooks.UserPromptSubmit += @{
                hooks = @(
                    @{
                        type = "command"
                        command = "powershell -ExecutionPolicy Bypass -File `"%USERPROFILE%\.claude\hooks\user-prompt-submit.ps1`""
                    }
                )
            }
            $settings | ConvertTo-Json -Depth 10 | Set-Content $SETTINGS_FILE
            Write-Host "  Added hook to settings.json" -ForegroundColor Green
        } catch {
            Write-Host "  Could not update settings.json - please add hook manually" -ForegroundColor Yellow
            Write-Host "  See README.md for manual configuration" -ForegroundColor Yellow
        }
    }
} else {
    # Create new settings.json
    $HOOK_CONFIG | ConvertTo-Json -Depth 10 | Set-Content $SETTINGS_FILE
    Write-Host "  Created settings.json with hook" -ForegroundColor Green
}

# Add aliases to PowerShell profile
$PROFILE_PATH = $PROFILE.CurrentUserAllHosts
$PROFILE_DIR = Split-Path -Parent $PROFILE_PATH

# Create profile directory if needed
if (-not (Test-Path $PROFILE_DIR)) {
    New-Item -ItemType Directory -Force -Path $PROFILE_DIR | Out-Null
}

# Create profile if needed
if (-not (Test-Path $PROFILE_PATH)) {
    New-Item -ItemType File -Force -Path $PROFILE_PATH | Out-Null
}

# Check if aliases already exist
$profileContent = Get-Content $PROFILE_PATH -Raw -ErrorAction SilentlyContinue
if ($profileContent -match "claude-update-plugins") {
    Write-Host "  Aliases already in PowerShell profile" -ForegroundColor Green
} else {
    $aliases = @'

# Skill Router aliases
function claude-update-plugins {
    Write-Host "Updating marketplaces..." -ForegroundColor Cyan
    $marketplacesDir = "$env:USERPROFILE\.claude\plugins\marketplaces"
    if (Test-Path $marketplacesDir) {
        Get-ChildItem $marketplacesDir -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            Write-Host "  -> $($_.Name)"
            git -C $_.FullName pull
        }
    }
    Write-Host "Regenerating skill catalog..." -ForegroundColor Cyan
    & "$env:USERPROFILE\.claude\bin\regenerate-catalog.ps1"
    Write-Host "Clearing plugin cache..." -ForegroundColor Cyan
    Remove-Item "$env:USERPROFILE\.claude\plugins\cache" -Recurse -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.claude\plugins\cache" | Out-Null
    Write-Host "Done! Restart Claude Code to load updated plugins." -ForegroundColor Green
}

function claude-update-project {
    param([string]$Path = ".")
    & "$env:USERPROFILE\.claude\bin\update-project-profile.ps1" $Path
}
'@
    Add-Content -Path $PROFILE_PATH -Value $aliases
    Write-Host "  Added aliases to PowerShell profile" -ForegroundColor Green
}

# Run initial catalog generation
Write-Host ""
Write-Host "Running initial plugin update..." -ForegroundColor Cyan
if (Test-Path "$CLAUDE_DIR\plugins\marketplaces") {
    & "$CLAUDE_DIR\bin\regenerate-catalog.ps1"
    Write-Host "  Skill catalog generated" -ForegroundColor Green
} else {
    Write-Host "  No plugins installed yet. Run 'claude-update-plugins' after installing plugins." -ForegroundColor Yellow
}

# Show welcome message
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host "  Skill Router installed successfully!" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""
Write-Host "HOW IT WORKS" -ForegroundColor White
Write-Host ""
Write-Host "  1. You type a prompt"
Write-Host "  2. Hook outputs reminder -> triggers skill analysis"
Write-Host "  3. Sonnet agent analyzes project + matches skills (smart)"
Write-Host "  4. User checkpoint -> you choose (select None to skip)"
Write-Host "  5. Claude activates selected skills and works"
Write-Host ""
Write-Host "  First prompt in a new project auto-generates ~/.claude/projects/{name}.yaml"
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""
Write-Host "COMMANDS" -ForegroundColor White
Write-Host ""
Write-Host "  claude-update-plugins    Update plugins + regenerate skill catalog"
Write-Host "  claude-update-project    Regenerate project profile (only if project type changed)"
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""
Write-Host "NEXT STEPS" -ForegroundColor White
Write-Host ""
Write-Host "  1. Restart PowerShell (or: . `$PROFILE)"
Write-Host "  2. Start Claude in any project"
Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
Write-Host ""
