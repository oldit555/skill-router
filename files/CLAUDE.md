# ~/.claude/CLAUDE.md

## SKILL ROUTER

### Cheat Sheet

```
AUTO:x        → Activate now: Skill(superpowers:x)
SUGGEST:x     → Ask user first, activate on "yes"
COMPATIBLE:x  → You decide: activate if relevant to task
No output     → Proceed normally

User override: "skip" | "use X instead" | "no skills" — always honored
```

---

### Processing Rules

**AUTO** — High confidence. Activate immediately.
```
Hook: SKILL_ROUTER → AUTO:systematic-debugging
You:  "Using systematic-debugging."
      [Skill(superpowers:systematic-debugging)]
```

**SUGGEST** — Medium confidence. Ask user, default to first.
```
Hook: SKILL_ROUTER → SUGGEST:test-driven-development

You:  "I recommend test-driven-development for this. Proceed?"
User: "yes" → [Skill(superpowers:test-driven-development)]
User: "skip" → Proceed without
```

**COMPATIBLE** — Context-dependent. You decide if relevant.
```
Hook: SKILL_ROUTER → AUTO:systematic-debugging | COMPATIBLE:root-cause-tracing,mobile-developer

You decide:
  - Is root-cause-tracing relevant? (tracing deep bugs → yes)
  - Is mobile-developer relevant? (React Native project → yes)

If relevant → Activate and announce
If not relevant → Ignore
```

**NONE** — Hook found no strong matches. YOU analyze and consider skills.

**ALWAYS** — Even when hook outputs something, YOU supplement:
1. Check `<available_skills>` in system context
2. Consider if additional skills/agents would help
3. Hook catches keywords, YOU understand intent

Example:
```
User: "analyze dashboard from user perspective, suggest improvements"
Hook: SKILL_ROUTER → SUGGEST:requesting-code-review (caught "improve")
You:  Also notice "user perspective" → suggest ui-ux-designer
```

The hook is a hint, not the full picture. Match semantically against installed skills.

---

### Semantic Skill Selection

**Don't follow fixed keyword maps. Think and suggest:**

1. Parse user's intent (what perspective/expertise do they want?)
2. Search `<available_skills>` descriptions for semantic matches
3. Suggest relevant combination to user before activating

**Example:**
```
User: "think from UX designer perspective about these cards"

You: "For this task I recommend combining:
     - brainstorming (structured design thinking)
     - ui-ux-designer (UX expertise, user research)

     Should I proceed with both?"
```

**After user confirms → activate and announce:** `"Using: brainstorming, ui-ux-designer"`

---

### No Deferred Activation

**NEVER say "I'll use X later" - activate NOW or don't commit.**

Bad:
```
"I'll use mobile-developer when implementing"
*proceeds to implement without it*
*rationalizes: "it's simple", "I know enough", "would slow me down"*
```

Good:
```
"Using: brainstorming, ui-ux-designer, mobile-developer"
*all activated at start*
*agents inform the entire process*
```

If you commit to a skill/agent → invoke it immediately.
If task has phases (design → implement) → re-confirm skills at each phase transition.

---

### Multiple Skills

When multiple skills activate, follow priority order:

```
1. brainstorming         (design before code)
2. systematic-debugging  (fix before build)
3. test-driven-development
4. requesting-code-review
5. verification-before-completion
```

**Example with COMPATIBLE:**
```
Hook: SKILL_ROUTER → AUTO:systematic-debugging | SUGGEST:debugger | COMPATIBLE:root-cause-tracing,mobile-developer

You: "Using systematic-debugging with root-cause-tracing (deep error investigation)."
     [Skill(superpowers:systematic-debugging)]
     [Also following root-cause-tracing patterns]

     "I recommend the debugger agent for this. Proceed?"
```

---

### Activation Syntax

| Type | Syntax |
|------|--------|
| Skill | `Skill(superpowers:skill-name)` |
| Agent | `Task` tool with `subagent_type: "agent-name"` |

Most skills: `superpowers:X`
Other namespaces: Check `<available_skills>` in system context

---

### User Override

User can ALWAYS override routing:

| User says | Action |
|-----------|--------|
| "skip" / "no skills" | Proceed without activating |
| "use X instead" | Activate X, remember preference |
| "stop" (mid-skill) | Exit skill, continue task |

---

### Never Skip AUTO

If hook says `AUTO`, activate it. Invalid excuses:
- "It's simple" — Hook already evaluated
- "We discussed this" — New request = new evaluation
- "I know what to do" — Skills ensure consistency

---

### Context7

When writing code or using library APIs:
- Auto-use Context7 MCP tools to fetch documentation
- Separate from skill routing — do both when applicable

---

## QUICK REFERENCE

```
AUTO       → Activate immediately, announce
SUGGEST    → Ask user
COMPATIBLE → You decide, announce if using
No output  → YOU analyze: check <available_skills>, suggest if helpful

Skills:  Skill(superpowers:name) or Skill(plugin:name)
Agents:  Task tool → subagent_type: "agent-name"

Priority: brainstorming → debugging → TDD → review → verification

Commands:
  claude-update-plugins    - Update plugins + regenerate catalog
  claude-refresh-project   - Regenerate current project profile
```
