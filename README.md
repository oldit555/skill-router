# Skill Router for Claude Code

Semantic skill matching for Claude Code. Sonnet reads the full skill catalog and matches your intent.

## Installation

### macOS / Linux

```bash
git clone https://github.com/YOUR_USERNAME/skill-router.git
cd skill-router
./install.sh
```

### Windows (PowerShell)

```powershell
git clone https://github.com/YOUR_USERNAME/skill-router.git
cd skill-router
powershell -ExecutionPolicy Bypass -File install.ps1
```

## How It Works

1. **You type a prompt**
2. **Hook outputs reminder** → triggers skill analysis
3. **Cold start (first session):** Sonnet reads catalog + scans project → saves to cache
4. **Warm start (cached):** Sonnet reads cache only → fast matching
5. **Resume (same session):** Sonnet uses memory → instant matching
6. **User checkpoint** → you pick skills or skip
7. **Claude activates** → works with selected skills

### Progress Messages

```
🔍 Scanning project...        # Cold start (~30 sec)
🔍 Loading cached analysis... # Warm start (fast)
🔍 Matching skills...         # Resume (instant)
```

### Why Sonnet?

- **Smart matching** → semantic understanding for skill matching
- **Project analysis** → scans package.json, configs for context
- **Affordable** → ~$0.01 cold start, ~$0.003 warm/resume
- **Cached** → analysis persists across sessions
- **Resume** → project + catalog stays in memory within session

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

## Cache System

First session in a project creates `~/.claude/projects/{name}.cache.yaml`:

- **Cold start:** Sonnet reads catalog + scans project → saves complete understanding to cache
- **Warm start:** Sonnet reads cache only (contains catalog + project analysis)
- **Resume:** Sonnet uses memory (no file reads)

Cache contains:
- Complete skill/agent catalog
- Project context (type, stack, frameworks)
- Sonnet's project analysis

## Commands

| Command | Description |
|---------|-------------|
| `claude-update-plugins` | Update plugins + regenerate catalog |
| `claude-update-project` | Clear cache (forces cold start next session) |

## Files

### macOS / Linux

```
~/.claude/
├── CLAUDE.md                    # Skill analysis instructions
├── skill-catalog.yaml           # Full skill descriptions
├── hooks/
│   └── user-prompt-submit.sh    # Reminder hook
├── bin/
│   ├── regenerate-catalog       # Rebuilds skill catalog
│   └── update-project-profile   # Clears project cache
└── projects/
    └── {name}.cache.yaml        # Cached analysis per project
```

### Windows

```
%USERPROFILE%\.claude\
├── CLAUDE.md                      # Skill analysis instructions
├── skill-catalog.yaml             # Full skill descriptions
├── hooks/
│   └── user-prompt-submit.ps1     # Reminder hook (PowerShell)
├── bin/
│   ├── regenerate-catalog.ps1     # Rebuilds skill catalog
│   └── update-project-profile.ps1 # Clears project cache
└── projects/
    └── {name}.cache.yaml          # Cached analysis per project
```

## Uninstall

### macOS / Linux

```bash
./uninstall.sh
```

### Windows (PowerShell)

```powershell
powershell -ExecutionPolicy Bypass -File uninstall.ps1
```
