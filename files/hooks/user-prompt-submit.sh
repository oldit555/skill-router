#!/bin/bash
# Smart Skill Router Hook
# Analyzes user requests and outputs skill/agent routing suggestions
# Output: SKILL_ROUTER → AUTO:x | SUGGEST:y | COMPATIBLE:z

set -euo pipefail

# Read user input
INPUT=$(cat)
INPUT_LOWER=$(echo "$INPUT" | tr '[:upper:]' '[:lower:]')

# Skip empty input
[[ -z "$INPUT_LOWER" ]] && exit 0

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
# SCORING
# ─────────────────────────────────────────────────────────────

score_debugging=0
score_tdd=0
score_brainstorming=0
score_code_review=0
score_verification=0
score_finishing=0
score_writing_plans=0
score_testing_antipatterns=0
score_root_cause=0
score_condition_waiting=0

score_debugger_agent=0
score_code_reviewer_agent=0
score_explore_agent=0
score_mobile_agent=0
score_backend_agent=0
score_frontend_agent=0

# ═══════════════════════════════════════════════════════════════
# STRONG SIGNALS (3 points)
# ═══════════════════════════════════════════════════════════════

# Debugging signals
if echo "$INPUT_LOWER" | grep -qE '(bug|error|crash|exception|failing|broken|not working|stacktrace)'; then
  score_debugging=3
  score_debugger_agent=2
fi

# Design signals
if echo "$INPUT_LOWER" | grep -qE '(design|architect|how should|which way|what approach|options|trade-?off|should i|best way)'; then
  score_brainstorming=3
fi

# ═══════════════════════════════════════════════════════════════
# MEDIUM SIGNALS (2 points)
# ═══════════════════════════════════════════════════════════════

# Implementation signals
if echo "$INPUT_LOWER" | grep -qE '(add|implement|create|build|write|new feature|develop)'; then
  score_tdd=$((score_tdd + 2))
fi

# Fix signals
if echo "$INPUT_LOWER" | grep -qE '(fix|repair|resolve|patch)'; then
  score_debugging=$((score_debugging + 2))
fi

# Test signals
if echo "$INPUT_LOWER" | grep -qE '(test|spec|coverage|tdd)'; then
  score_tdd=$((score_tdd + 2))
  score_testing_antipatterns=2
fi

# Flaky test signals
if echo "$INPUT_LOWER" | grep -qE '(flaky|intermittent|sometimes|race condition|timing)'; then
  score_condition_waiting=2
fi

# Deep debugging signals
if echo "$INPUT_LOWER" | grep -qE '(trace|root cause|where does|why is|call stack)'; then
  score_root_cause=2
fi

# Review signals
if echo "$INPUT_LOWER" | grep -qE '(review|check my|look at my|code review)'; then
  score_code_review=2
  score_code_reviewer_agent=2
fi

# Completion signals
if echo "$INPUT_LOWER" | grep -qE '(done|finish|complete|ready|merge|ship|deploy|pr|pull request)'; then
  score_verification=2
  score_finishing=2
fi

# Refactor signals
if echo "$INPUT_LOWER" | grep -qE '(refactor|clean up|improve|reorganize)'; then
  score_code_review=$((score_code_review + 2))
fi

# Plan signals
if echo "$INPUT_LOWER" | grep -qE '(plan|steps|breakdown|roadmap|strategy)'; then
  score_writing_plans=2
fi

# Frontend signals
if echo "$INPUT_LOWER" | grep -qE '(component|ui|style|css|layout|responsive)'; then
  score_frontend_agent=2
fi

# Backend signals
if echo "$INPUT_LOWER" | grep -qE '(api|endpoint|database|query|backend|server)'; then
  score_backend_agent=2
fi

# ═══════════════════════════════════════════════════════════════
# WEAK SIGNALS (1 point)
# ═══════════════════════════════════════════════════════════════

# Exploration signals
if echo "$INPUT_LOWER" | grep -qE '(explore|find|search|where|look for)'; then
  score_explore_agent=1
fi

# ═══════════════════════════════════════════════════════════════
# PROJECT CONTEXT BOOSTS
# ═══════════════════════════════════════════════════════════════

if [[ -f "$PROJECT_PROFILE" ]]; then
  # Mobile boost
  if grep -q "mobile-developer:" "$PROJECT_PROFILE" 2>/dev/null; then
    boost=$(grep "mobile-developer:" "$PROJECT_PROFILE" | grep -oE '[+-]?[0-9]+' | head -1 || echo 0)
    score_mobile_agent=$((score_mobile_agent + boost))
  fi

  # Backend boost
  if grep -q "backend-architect:" "$PROJECT_PROFILE" 2>/dev/null; then
    boost=$(grep "backend-architect:" "$PROJECT_PROFILE" | grep -oE '[+-]?[0-9]+' | head -1 || echo 0)
    score_backend_agent=$((score_backend_agent + boost))
  fi

  # Frontend boost
  if grep -q "frontend-developer:" "$PROJECT_PROFILE" 2>/dev/null; then
    boost=$(grep "frontend-developer:" "$PROJECT_PROFILE" | grep -oE '[+-]?[0-9]+' | head -1 || echo 0)
    score_frontend_agent=$((score_frontend_agent + boost))
  fi
fi

# ═══════════════════════════════════════════════════════════════
# CONFLICT RESOLUTION
# ═══════════════════════════════════════════════════════════════

# If both debugging and TDD match, context decides
if [[ $score_debugging -gt 0 && $score_tdd -gt 0 ]]; then
  if echo "$INPUT_LOWER" | grep -qE '(bug|error|crash|broken|not working|failing)'; then
    score_tdd=0
  elif echo "$INPUT_LOWER" | grep -qE '(add|create|new|implement|build)'; then
    if ! echo "$INPUT_LOWER" | grep -qE '(error|bug|crash)'; then
      score_debugging=0
    fi
  fi
fi

# If brainstorming matches, delay TDD
if [[ $score_brainstorming -ge 2 && $score_tdd -gt 0 && $score_tdd -lt 3 ]]; then
  score_tdd=1
fi

# ═══════════════════════════════════════════════════════════════
# BUILD OUTPUT WITH COMPATIBILITY
# ═══════════════════════════════════════════════════════════════

auto_items=""
suggest_items=""
compatible_items=""

# Skills - AUTO (score >= 3)
[[ $score_brainstorming -ge 3 ]] && auto_items="${auto_items}brainstorming,"
[[ $score_debugging -ge 3 ]] && auto_items="${auto_items}systematic-debugging,"
[[ $score_tdd -ge 3 ]] && auto_items="${auto_items}test-driven-development,"
[[ $score_code_review -ge 3 ]] && auto_items="${auto_items}requesting-code-review,"
[[ $score_verification -ge 3 ]] && auto_items="${auto_items}verification-before-completion,"

# Skills - SUGGEST (score >= 2, < 3)
[[ $score_brainstorming -ge 2 && $score_brainstorming -lt 3 ]] && suggest_items="${suggest_items}brainstorming,"
[[ $score_debugging -ge 2 && $score_debugging -lt 3 ]] && suggest_items="${suggest_items}systematic-debugging,"
[[ $score_tdd -ge 2 && $score_tdd -lt 3 ]] && suggest_items="${suggest_items}test-driven-development,"
[[ $score_code_review -ge 2 && $score_code_review -lt 3 ]] && suggest_items="${suggest_items}requesting-code-review,"
[[ $score_verification -ge 2 && $score_verification -lt 3 ]] && suggest_items="${suggest_items}verification-before-completion,"
[[ $score_finishing -ge 2 ]] && suggest_items="${suggest_items}finishing-a-development-branch,"
[[ $score_writing_plans -ge 2 ]] && suggest_items="${suggest_items}writing-plans,"

# ═══════════════════════════════════════════════════════════════
# COMPATIBLE ITEMS (Claude decides if relevant)
# Based on what's in AUTO/SUGGEST
# ═══════════════════════════════════════════════════════════════

# If debugging is active, these MIGHT be relevant
if [[ $score_debugging -ge 2 ]]; then
  [[ $score_root_cause -ge 1 ]] && compatible_items="${compatible_items}root-cause-tracing,"
  [[ $score_condition_waiting -ge 1 ]] && compatible_items="${compatible_items}condition-based-waiting,"
fi

# If TDD is active, testing-anti-patterns is compatible
if [[ $score_tdd -ge 2 ]]; then
  compatible_items="${compatible_items}testing-anti-patterns,"
fi

# If brainstorming is active, writing-plans might follow
if [[ $score_brainstorming -ge 2 ]]; then
  compatible_items="${compatible_items}writing-plans,"
fi

# If code review is active, verification might be relevant
if [[ $score_code_review -ge 2 ]]; then
  compatible_items="${compatible_items}verification-before-completion,"
fi

# Agents - SUGGEST (never AUTO)
[[ $score_debugger_agent -ge 2 ]] && suggest_items="${suggest_items}debugger,"
[[ $score_code_reviewer_agent -ge 2 ]] && suggest_items="${suggest_items}code-reviewer,"
[[ $score_explore_agent -ge 2 ]] && suggest_items="${suggest_items}Explore,"

# Project-boosted agents go to COMPATIBLE (Claude decides based on context)
[[ $score_mobile_agent -ge 2 ]] && compatible_items="${compatible_items}mobile-developer,"
[[ $score_backend_agent -ge 2 ]] && compatible_items="${compatible_items}backend-architect,"
[[ $score_frontend_agent -ge 2 ]] && compatible_items="${compatible_items}frontend-developer,"

# Remove trailing commas
auto_items=${auto_items%,}
suggest_items=${suggest_items%,}
compatible_items=${compatible_items%,}

# Remove duplicates between categories (COMPATIBLE shouldn't repeat AUTO/SUGGEST)
# Simple approach: if item is in auto or suggest, remove from compatible
for item in ${auto_items//,/ } ${suggest_items//,/ }; do
  compatible_items=$(echo "$compatible_items" | sed "s/\b$item\b,\?//g" | sed 's/,$//')
done

# ═══════════════════════════════════════════════════════════════
# OUTPUT
# ═══════════════════════════════════════════════════════════════

output=""

if [[ -n "$auto_items" ]]; then
  output="AUTO:$auto_items"
fi

if [[ -n "$suggest_items" ]]; then
  [[ -n "$output" ]] && output="$output | "
  output="${output}SUGGEST:$suggest_items"
fi

if [[ -n "$compatible_items" ]]; then
  [[ -n "$output" ]] && output="$output | "
  output="${output}COMPATIBLE:$compatible_items"
fi

if [[ -n "$output" ]]; then
  echo "SKILL_ROUTER → $output"
else
  echo "SKILL_ROUTER → NONE (you analyze: check <available_skills>)"
fi
