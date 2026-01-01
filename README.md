# Skill Router for Claude Code

Semantic skill matching for Claude Code. Sonnet reads the full skill catalog and matches your intent.

## Installation

```bash
git clone https://github.com/YOUR_USERNAME/skill-router.git
cd skill-router
./install.sh
```

## How It Works

1. **You type a prompt**
2. **Hook outputs reminder** → triggers skill analysis
3. **First prompt:** Sonnet analyzes project + reads catalog → matches → save agent_id
4. **Subsequent:** Resume sonnet (project + catalog in memory) → matches
5. **User checkpoint** → you pick skills or skip
6. **Claude activates** → works with selected skills

### Why Sonnet?

- **Smart matching** → better semantic understanding for skill matching
- **Project analysis** → reads package.json, configs for context
- **Affordable** → ~$0.01 first prompt, ~$0.003 subsequent
- **Resume** → project + catalog stays in memory, fast matching
- **Simple** → one agent does it all

## Example

```
You: "check my work before I push"

─────────────────────────────────────────
🛑 SKILL_ROUTER
─────────────────────────────────────────
On EVERY prompt (default = analyze):
1. Spawn/resume sonnet → get matches
2. Output **Skill Analysis** block
3. If matches → AskUserQuestion
4. THEN proceed
Skip ONLY: definitions, typos, 'skip'
─────────────────────────────────────────

Claude: **Skill Analysis**
        - Intent: wants code review before pushing
        - Matches: superpowers:requesting-code-review
        - Recommendation: superpowers:requesting-code-review

        ┌─────────────────────────────────────────────┐
        │ How would you like to proceed?              │
        │ ○ Use superpowers:requesting-code-review    │
        │ ○ None                                      │
        └─────────────────────────────────────────────┘

You: [Selects skill]

Claude: [Activates Skill(superpowers:requesting-code-review)]
```

## Project Profiles

First prompt in a new project auto-generates `~/.claude/projects/{name}.yaml`:

```yaml
project:
  name: my-app
  type: mobile

detected:
  stack: [expo, react-native, typescript]

skill_boosts:
  multi-platform-apps:mobile-developer: +3
  multi-platform-apps:frontend-developer: +1
```

## Commands

| Command | Description |
|---------|-------------|
| `claude-update-plugins` | Update plugins + regenerate catalog |
| `claude-update-project` | Regenerate project profile |

## Files

```
~/.claude/
├── CLAUDE.md                    # Skill analysis instructions
├── skill-catalog.yaml           # Full skill descriptions
├── hooks/
│   └── user-prompt-submit.sh    # Reminder hook
├── bin/
│   ├── regenerate-catalog       # Rebuilds skill catalog
│   └── update-project-profile
└── projects/
    └── {name}.yaml              # Project profiles
```

## Uninstall

```bash
./uninstall.sh
```
