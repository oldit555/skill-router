# Skill Router for Claude Code

Smart skill and agent routing for Claude Code. Automatically suggests relevant skills/agents based on your prompts.

## Installation

```bash
git clone https://github.com/YOUR_USERNAME/skill-router.git
cd skill-router
./install.sh
```

## How It Works

1. **You type a prompt**
2. **Hook analyzes keywords** → outputs hints (AUTO/SUGGEST/COMPATIBLE/NONE)
3. **Claude does semantic matching** → suggests relevant skills/agents from installed plugins
4. **You confirm** → Claude activates and works

### First Prompt in a New Project

- Auto-detects stack (React Native, Go, Python, etc.)
- Creates project profile with skill boosts
- No manual setup needed

## Commands

| Command | Description |
|---------|-------------|
| `claude-update-plugins` | Update plugins + regenerate skill catalog |
| `claude-refresh-project` | Regenerate project profile (only if project type changed) |

## Confidence Levels

| Level | Behavior |
|-------|----------|
| `AUTO` | Activate immediately |
| `SUGGEST` | Ask user first |
| `COMPATIBLE` | Claude decides based on context |
| `NONE` | Claude does semantic analysis |

## Example

```
You: "add push notifications"

SKILL_ROUTER → SUGGEST:test-driven-development | COMPATIBLE:mobile-developer

Claude: "For this task I recommend:
        - test-driven-development (implementation approach)
        - mobile-developer (React Native expertise)

        Should I proceed with both?"

You: "yes"

Claude: "Using: test-driven-development, mobile-developer"
```

## Files Installed

```
~/.claude/
├── CLAUDE.md                    # Skill selection instructions
├── skill-overrides.yaml         # Manual keyword tuning
├── skill-catalog.yaml           # Auto-generated skill list
├── hooks/
│   └── user-prompt-submit.sh    # The routing hook
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
