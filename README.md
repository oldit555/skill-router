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
5. **User checkpoint** → interactive prompt asks how to proceed (prevents Claude from ignoring its own recommendations)
6. **You choose** → Claude activates and works

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
Before responding, you MUST:
1. Read skill catalog + project profile (first prompt only)
2. Match user intent against skills (be INCLUSIVE)
3. Output **Skill Analysis** block
4. If ANY matches → AskUserQuestion checkpoint
5. If no matches → proceed directly
─────────────────────────────────────────

Claude: **Skill Analysis**
        - Intent: wants feedback on code before pushing
        - Matches: requesting-code-review (reviews implementation)
        - Recommendation: requesting-code-review

        ┌─────────────────────────────────────────┐
        │ How would you like to proceed?          │
        │                                         │
        │ ○ Use requesting-code-review            │
        │   Reviews implementation quality        │
        │                                         │
        │ ○ None                                  │
        │   Proceed without skills/agents         │
        └─────────────────────────────────────────┘

You: [Selects "Use requesting-code-review"]

Claude: [Activates skill, runs code review]
```

### Multiple Skills/Agents

When multiple skills match, options are grouped (max 4 allowed):

```
You: "design and build a settings screen"

Claude: **Skill Analysis**
        - Intent: design + implement new feature
        - Matches:
          - brainstorming (design before code)
          - ui-ux-designer (interface design)
          - mobile-developer (React Native)
          - test-driven-development (implementation)
        - Recommendation: brainstorming → ui-ux + mobile-developer

        ┌─────────────────────────────────────────┐
        │ Which skills/agents do you want to use? │
        │                                         │
        │ ☐ Use all                               │
        │   brainstorming + ui-ux + mobile + TDD  │
        │                                         │
        │ ☐ Suggested                             │
        │   brainstorming → ui-ux + mobile        │
        │                                         │
        │ ☐ Implementation                        │
        │   TDD (the remaining)                   │
        │                                         │
        │ ☐ None                                  │
        │   Proceed without skills/agents         │
        └─────────────────────────────────────────┘

You: [Select "Suggested"]

Claude: [Activates in priority order]
```

### User Checkpoint

The interactive prompt is a **blocking checkpoint** that prevents Claude from recommending skills but then ignoring its own recommendations.

**The problem it solves:**
```
Before: Claude recommends code-reviewer → starts working manually anyway → "forgot" to use it
After:  Claude recommends code-reviewer → MUST wait for your choice → actually uses it
```

**Your options:**
| Selection | What happens |
|-----------|--------------|
| Use all / Suggested | Claude activates selected skills/agents |
| None | Proceed without skills (your explicit choice) |
| Other... | Type custom instructions |

## Project Profiles

First prompt in a new project auto-generates `~/.claude/projects/{name}.yaml`:

```yaml
project:
  name: my-app
  type: mobile

detected:
  stack: [expo, react-native, typescript]

skill_boosts:
  mobile-developer: +3    # Strong hint for this project
  frontend-developer: +1  # Mild hint
```

Claude reads this once per session and uses `skill_boosts` as hints when matching - boosted skills/agents are more likely to be recommended for your project type.

- Auto-detects stack (React Native, Go, Python, etc.)
- No manual setup needed
- Regenerate with: `claude-refresh-project`

## Commands

| Command | Description |
|---------|-------------|
| `claude-update-plugins` | Update plugins + regenerate skill catalog |
| `claude-refresh-project` | Regenerate project profile (only if project type changed) |

## Files Installed

```
~/.claude/
├── CLAUDE.md                    # Skill analysis instructions
├── skill-catalog.yaml           # Auto-generated skill list
├── hooks/
│   └── user-prompt-submit.sh    # Simple reminder hook
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
