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
# LAZY PROJECT PROFILE GENERATION
# ─────────────────────────────────────────────────────────────

if [[ ! -f "$PROJECT_PROFILE" ]] && [[ -x "$CLAUDE_DIR/bin/regenerate-project-profile" ]]; then
  nohup "$CLAUDE_DIR/bin/regenerate-project-profile" "$PWD" > /dev/null 2>&1 &
fi

# ─────────────────────────────────────────────────────────────
# OUTPUT - Just a reminder for Claude
# ─────────────────────────────────────────────────────────────

echo "─────────────────────────────────────────"
echo "SKILL_ROUTER"
echo "─────────────────────────────────────────"
echo "Before responding, you MUST:"
echo "1. Read skill catalog + project profile (first prompt only)"
echo "2. Match user intent against skills (be INCLUSIVE)"
echo "3. Output **Skill Analysis** block"
echo "4. If ANY matches → AskUserQuestion checkpoint"
echo "5. If no matches → proceed directly"
echo "─────────────────────────────────────────"
