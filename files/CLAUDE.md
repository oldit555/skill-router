# ~/.claude/CLAUDE.md

## SKILL ROUTER

### ⚠️ MANDATORY SKILL ANALYSIS

**On EVERY prompt, before responding, you MUST:**

1. **Understand intent** — What does the user actually need? (not what words they used)
2. **Scan `<available_skills>`** — Read descriptions, find semantic matches
3. **Output visible analysis** — Show your work (format below)
4. **Recommend or proceed** — Suggest matches OR state "none needed"

**Output this block for action requests:**
```
**Skill Analysis**
- Intent: [what user actually needs]
- Matches: [skill/agent names + why they match, or "none"]
- Recommendation: [skill(s)/agent(s) to use, or NONE]
```

**Then either:**
- Matches found → "I recommend X (and Y) for this. Proceed?"
- No matches → Proceed directly (still show analysis block)

**Skip analysis ONLY if:**
- Pure informational question ("what does X mean?")
- User said "skip" or "no skills"
- Already executing inside a skill

---

### Examples

**Single skill:**
```
User: "analyze my changes before commit"

**Skill Analysis**
- Intent: wants feedback on code changes before committing
- Matches: requesting-code-review (reviews implementation)
- Recommendation: requesting-code-review

"I recommend **requesting-code-review** for this. Proceed?"
```

**Multiple skills/agents:**
```
User: "design and build push notifications"

**Skill Analysis**
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

**No skills needed:**
```
User: "what does useEffect do?"

**Skill Analysis**
- Intent: explanation (informational)
- Matches: none
- Recommendation: NONE

[Answers directly]
```

---

### Hook Hints

The hook provides keyword-based hints to assist your analysis:

```
HINTS: AUTO:x      → Strong match, activate immediately
HINTS: SUGGEST:x   → Medium match, ask user first
HINTS: COMPATIBLE:x → Context-dependent, you decide
HINTS: none        → No keyword matches, full semantic analysis needed
```

**Important:** Hook hints are helpers, not the full picture. YOU do semantic matching.

---

### Processing Hook Hints

When the hook outputs hints, use them to accelerate your analysis:

**AUTO** — High confidence. Include in your analysis, activate immediately.
```
HINTS: AUTO:systematic-debugging

**Skill Analysis**
- Intent: [from your analysis]
- Matches: systematic-debugging (AUTO from hook) + [your additions]
- Recommendation: systematic-debugging

"Using systematic-debugging." [Skill(superpowers:systematic-debugging)]
```

**SUGGEST** — Medium confidence. Include in analysis, ask user.
```
HINTS: SUGGEST:test-driven-development

**Skill Analysis**
- Intent: [from your analysis]
- Matches: test-driven-development (SUGGEST from hook)
- Recommendation: test-driven-development

"I recommend test-driven-development. Proceed?"
```

**COMPATIBLE** — Context-dependent. You decide if relevant based on task.
```
HINTS: AUTO:systematic-debugging | COMPATIBLE:root-cause-tracing,mobile-developer

**Skill Analysis**
- Intent: debugging a deep issue in React Native app
- Matches:
  - systematic-debugging (AUTO)
  - root-cause-tracing (relevant - need to trace deep)
  - mobile-developer (relevant - RN project)
- Recommendation: all three

"Using systematic-debugging with root-cause-tracing. Also using mobile-developer agent for RN context."
```

**Remember:** Hook hints + your semantic analysis = complete picture. Always add matches the hook missed.

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
EVERY PROMPT:
  1. Understand intent (not keywords)
  2. Scan <available_skills> semantically
  3. Output **Skill Analysis** block
  4. Recommend or state NONE

HOOK HINTS:
  AUTO:x       → Activate immediately
  SUGGEST:x    → Ask user first
  COMPATIBLE:x → You decide if relevant
  none         → Full semantic analysis needed

ACTIVATION:
  Skills:  Skill(superpowers:name) or Skill(plugin:name)
  Agents:  Task tool → subagent_type: "agent-name"

PRIORITY ORDER:
  brainstorming → debugging → TDD → review → verification

COMMANDS:
  claude-update-plugins    - Update plugins + regenerate catalog
  claude-refresh-project   - Regenerate current project profile
```
