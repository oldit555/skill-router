#!/bin/bash
# Skill Router Hook
# Simple reminder to trigger Claude's semantic skill analysis
# All intelligence is in Claude's matching, not keyword heuristics

set -euo pipefail

# Read user input
INPUT=$(cat)

# Skip empty input
[[ -z "$INPUT" ]] && exit 0

# Config paths
CLAUDE_DIR="$HOME/.claude"
PROJECT_NAME=$(basename "$PWD")
PROJECT_PROFILE="$CLAUDE_DIR/projects/${PROJECT_NAME}.yaml"

# ─────────────────────────────────────────────────────────────
# ENSURE PROJECT PROFILE EXISTS (synchronous)
# ─────────────────────────────────────────────────────────────

if [[ ! -f "$PROJECT_PROFILE" ]] && [[ -x "$CLAUDE_DIR/bin/update-project-profile" ]]; then
  # Run synchronously so profile is ready before sonnet agent reads it
  "$CLAUDE_DIR/bin/update-project-profile" "$PWD" > /dev/null 2>&1
fi

# ─────────────────────────────────────────────────────────────
# OUTPUT - Just a reminder for Claude
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
