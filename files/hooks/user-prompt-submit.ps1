# Skill Router Hook (PowerShell)
# Simple reminder to trigger Claude's semantic skill analysis
# All intelligence is in Claude's matching, not keyword heuristics

$ErrorActionPreference = "Stop"

# Read user input from stdin
$userPrompt = [Console]::In.ReadToEnd()

# Skip empty input
if ([string]::IsNullOrWhiteSpace($userPrompt)) {
    exit 0
}

# ─────────────────────────────────────────────────────────────
# OUTPUT - Just a reminder for Claude
# Sonnet scans projects directly now (no pre-generated profile)
# ─────────────────────────────────────────────────────────────

Write-Output "─────────────────────────────────────────"
Write-Output "🛑 SKILL_ROUTER - MANDATORY CHECK"
Write-Output "─────────────────────────────────────────"
Write-Output "BEFORE responding, you MUST:"
Write-Output "1. Spawn/resume sonnet → get matches"
Write-Output "2. Output **Skill Analysis** block"
Write-Output "3. If matches → AskUserQuestion"
Write-Output "4. ONLY THEN proceed"
Write-Output ""
Write-Output "⚠️ NO EXCEPTIONS after message #1, #5, or #50"
Write-Output "⚠️ 'I already know what to do' = VIOLATION"
Write-Output "⚠️ Skip ONLY: definitions, typos, 'skip'"
Write-Output "─────────────────────────────────────────"
