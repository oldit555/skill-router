# regenerate-catalog.ps1 - Builds skill-catalog.yaml from plugin files
# Scans skills/ and agents/ directories in INSTALLED plugins only (cache)

$ErrorActionPreference = "Stop"

$CLAUDE_DIR = "$env:USERPROFILE\.claude"
$PLUGINS_DIR = "$CLAUDE_DIR\plugins\cache"
$CATALOG = "$CLAUDE_DIR\skill-catalog.yaml"

Write-Host "Regenerating skill catalog..."

# Files to skip (not real skills/agents)
$SkipNames = @(
    'README', 'CHANGELOG', 'CREATION-LOG', 'EXAMPLES', 'COMMANDLINE-USAGE', 'MCP-TOOLS',
    'test-pressure', 'test-academic', 'CLAUDE_MD_TESTING', 'example-settings', 'example-skill',
    'real-world-examples', 'parsing-techniques', 'component-patterns', 'manifest-reference',
    'patterns', 'migration', 'advanced', 'effort', 'prompt-snippets', 'authentication',
    'server-types', 'system-prompt-design', 'triggering-examples'
)

function Should-Skip {
    param([string]$Name)

    # Skip names starting with [
    if ($Name.StartsWith('[')) { return $true }

    return $SkipNames -contains $Name
}

function Get-SourcePriority {
    param([string]$Source)

    switch -Wildcard ($Source) {
        'superpowers' { return 1 }
        'superpowers-*' { return 1 }
        'claude-code-workflows' { return 2 }
        'anthropic-official' { return 3 }
        'claude-plugins-official' { return 3 }
        default { return 9 }
    }
}

function Get-SourcePlugin {
    param([string]$FilePath)

    # Extract plugin name from path
    # Cache: plugins/cache/{marketplace}/{plugin-name}/{version}/skills/...
    if ($FilePath -match 'plugins[/\\]cache[/\\][^/\\]+[/\\]([^/\\]+)[/\\]') {
        return $Matches[1]
    }
    # Marketplaces: plugins/marketplaces/{marketplace}/plugins/{plugin-name}/
    if ($FilePath -match 'plugins[/\\]marketplaces[/\\][^/\\]+[/\\]plugins[/\\]([^/\\]+)[/\\]') {
        return $Matches[1]
    }
    if ($FilePath -match 'plugins[/\\]marketplaces[/\\]([^/\\]+)[/\\]') {
        return $Matches[1]
    }
    return 'unknown'
}

# Hashtables for deduplication (name -> {priority, source, description})
$Skills = @{}
$Agents = @{}

function Collect-Items {
    param(
        [string]$PathPattern,
        [hashtable]$OutputHash
    )

    $count = 0
    $skipped = 0

    if (-not (Test-Path $PLUGINS_DIR)) {
        return @{ Count = 0; Skipped = 0 }
    }

    Get-ChildItem -Path $PLUGINS_DIR -Recurse -Filter "*.md" -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -match $PathPattern } |
        ForEach-Object {
            $file = $_
            $filename = $file.BaseName

            # Determine item name
            if ($filename -eq 'SKILL' -or $filename -eq 'AGENT') {
                $itemName = $file.Directory.Name
            } else {
                $itemName = $filename
            }

            # Skip if in skip list
            if (Should-Skip $itemName) {
                $skipped++
                return
            }

            # Extract description
            $description = ""
            $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
            if ($content -match '(?m)^description:\s*"?([^"\r\n]+)"?') {
                $description = $Matches[1].Trim()
            }

            # Skip if no meaningful description
            if ([string]::IsNullOrWhiteSpace($description) -or $description.Length -lt 20) {
                $skipped++
                return
            }

            # Get source plugin
            $sourcePlugin = Get-SourcePlugin $file.FullName
            $priority = Get-SourcePriority $sourcePlugin

            # Handle duplicates - keep higher priority (lower number)
            if ($OutputHash.ContainsKey($itemName)) {
                $existing = $OutputHash[$itemName]
                if ($existing.Priority -le $priority) {
                    return
                }
            }

            $OutputHash[$itemName] = @{
                Priority = $priority
                Source = $sourcePlugin
                Description = $description
            }

            $count++
        }

    return @{ Count = $count; Skipped = $skipped }
}

# Collect skills and agents
Write-Host "Scanning skills..."
$skillResult = Collect-Items -PathPattern '[/\\]skills[/\\]' -OutputHash $Skills

Write-Host "Scanning agents..."
$agentResult = Collect-Items -PathPattern '[/\\]agents[/\\]' -OutputHash $Agents

# Generate catalog
$catalogContent = @"
# Skill Catalog - Sonnet reads this for matching
# Regenerate with: regenerate-catalog or claude-update-plugins
# Auto-generated from plugin skills/ and agents/ directories

generated: $(Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz")
skill_count: $($Skills.Count)
agent_count: $($Agents.Count)

skills:
"@

# Add skills (sorted by name)
$Skills.GetEnumerator() | Sort-Object Name | ForEach-Object {
    $fullName = "$($_.Value.Source):$($_.Key)"
    $catalogContent += "`n  ${fullName}: `"$($_.Value.Description)`""
}

$catalogContent += "`n`nagents:"

# Add agents (sorted by name)
$Agents.GetEnumerator() | Sort-Object Name | ForEach-Object {
    $fullName = "$($_.Value.Source):$($_.Key)"
    $catalogContent += "`n  ${fullName}: `"$($_.Value.Description)`""
}

# Write catalog
$catalogContent | Set-Content -Path $CATALOG -Encoding UTF8

# Summary
Write-Host ""
Write-Host "Catalog generated: $CATALOG"
Write-Host "Skills: $($Skills.Count)"
Write-Host "Agents: $($Agents.Count)"
Write-Host ""
Write-Host "Tip: Run 'claude-update-project' for fresh project analysis if new skills are relevant."
Write-Host ""
