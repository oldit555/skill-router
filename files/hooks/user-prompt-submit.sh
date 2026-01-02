#!/bin/bash
# Skill Router Hook
# Simple reminder to trigger Claude's semantic skill analysis
# All intelligence is in Claude's matching, not keyword heuristics

set -euo pipefail

# Read user input
INPUT=$(cat)

# Skip empty input
[[ -z "$INPUT" ]] && exit 0

# ─────────────────────────────────────────────────────────────
# OUTPUT - Just a reminder for Claude
# Sonnet scans projects directly now (no pre-generated profile)
# ─────────────────────────────────────────────────────────────

echo "─────────────────────────────────────────"
echo "🛑 SKILL_ROUTER"
echo "─────────────────────────────────────────"
echo "On EVERY prompt (default = analyze):"
echo "1. Spawn/resume sonnet → get matches"
echo "2. Output **Skill Analysis** block"
echo "3. If matches → AskUserQuestion"
echo "4. THEN proceed"
echo "Skip ONLY: definitions, typos, 'skip'"
echo "─────────────────────────────────────────"
