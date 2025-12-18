# Skill Router for Claude Code

Smart skill and agent routing for Claude Code. Semantic matching suggests relevant skills/agents based on your intent, not just keywords.

## Installation

```bash
git clone https://github.com/YOUR_USERNAME/skill-router.git
cd skill-router
./install.sh
```

## How It Works

1. **You type a prompt**
2. **Hook outputs reminder** → forces Claude to analyze before responding
3. **Claude does semantic matching** → scans all installed skills, matches against your intent
4. **Claude shows analysis** → visible skill analysis block (you see the reasoning)
5. **You confirm** → Claude activates and works

### Key Feature: Semantic Matching

Claude matches your **intent**, not just keywords:

| You say | Claude understands | Suggests |
|---------|-------------------|----------|
| "analyze my changes before commit" | wants code feedback | requesting-code-review |
| "help me build notifications" | design + implement | brainstorming → TDD |
| "why is this crashing" | needs debugging | systematic-debugging |
| "what does useEffect do" | just a question | NONE (answers directly) |

## Example

```
You: "check my work before I push"

─────────────────────────────────────────
SKILL_ROUTER
─────────────────────────────────────────
ACTION REQUIRED: Before responding, you MUST:
1. Understand user's intent (not just keywords)
2. Scan <available_skills> for semantic matches
3. Output visible **Skill Analysis** block
4. Recommend skill(s)/agent(s) or state NONE
─────────────────────────────────────────
HINTS: SUGGEST:requesting-code-review
─────────────────────────────────────────

Claude: **Skill Analysis**
        - Intent: wants feedback on code before pushing
        - Matches: requesting-code-review (reviews implementation)
        - Recommendation: requesting-code-review

        "I recommend **requesting-code-review** for this. Proceed?"

You: "yes"

Claude: [Activates skill, runs code review]
```

### Multiple Skills/Agents

```
You: "design and build a settings screen"

Claude: **Skill Analysis**
        - Intent: design + implement new feature
        - Matches:
          - brainstorming (design before code)
          - test-driven-development (implementation)
          - mobile-developer agent (React Native)
        - Recommendation: brainstorming → then TDD + mobile-developer

        "This needs design first, then implementation. I recommend:
        1. **brainstorming** (refine the design)
        2. **test-driven-development** + **mobile-developer** (build it)

        Start with brainstorming?"
```

## First Prompt in a New Project

- Auto-detects stack (React Native, Go, Python, etc.)
- Creates project profile with skill boosts
- No manual setup needed

## Commands

| Command | Description |
|---------|-------------|
| `claude-update-plugins` | Update plugins + regenerate skill catalog |
| `claude-refresh-project` | Regenerate project profile (only if project type changed) |

## Hook Hints

The hook provides keyword-based hints to assist semantic analysis:

| Hint | Meaning |
|------|---------|
| `AUTO:x` | Strong keyword match → activate immediately |
| `SUGGEST:x` | Medium match → ask user first |
| `COMPATIBLE:x` | Context-dependent → Claude decides |
| `none` | No keyword matches → full semantic analysis |

**Note:** Hints are helpers. Claude always does semantic matching on top.

## Files Installed

```
~/.claude/
├── CLAUDE.md                    # Mandatory skill analysis instructions
├── skill-overrides.yaml         # Manual keyword tuning
├── skill-catalog.yaml           # Auto-generated skill list
├── hooks/
│   └── user-prompt-submit.sh    # The routing hook (runs every prompt)
├── bin/
│   ├── regenerate-catalog       # Rebuilds skill catalog
│   └── regenerate-project-profile # Detects project stack
└── projects/
    └── {project-name}.yaml      # Auto-generated project profiles
```

## Uninstall

```bash
./uninstall.sh
```

## Requirements

- Claude Code CLI
- zsh (for aliases)
- jq (optional, for merging settings.json)
