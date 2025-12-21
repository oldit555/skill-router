# ~/.claude/CLAUDE.md

## SKILL ROUTER

### 🛑 STOP - READ THIS FIRST

**If your Skill Analysis finds ANY matches (1 or more), you MUST call `AskUserQuestion` tool.**

There are NO exceptions. You cannot:
- Rationalize why a match "doesn't really apply" and skip
- Say "straightforward task" and proceed manually
- Pick only one match when you found multiple
- Write any response before the user chooses

**Violation = Breaking the rules. No rationalization allowed.**

---

### ⚠️ MANDATORY SKILL ANALYSIS

**On EVERY prompt, before responding, you MUST:**

1. **Understand intent** — What does the user actually need? (not what words they used)
2. **Know your skills** — If you haven't read the skill catalog this session, read `~/.claude/skill-catalog.yaml` once. Remember it for subsequent prompts.
3. **Semantic matching** — Match user intent against skill descriptions
4. **Output visible analysis** — Show your work (format below)
5. **Checkpoint or proceed** — If ANY matches, ask user; if none, proceed

**Reading files (token optimization):**
- **First prompt of session:** Read `~/.claude/skill-catalog.yaml` and `~/.claude/projects/{project-name}.yaml` (if exists)
- **Subsequent prompts:** Use from memory - DO NOT re-read
- **After conversation compact:** Re-read both files (memory was cleared)

Use `skill_boosts` from project profile as hints - boosted skills/agents are more likely relevant.

**Matching guidance - be INCLUSIVE, not conservative:**

⚠️ **ERR ON THE SIDE OF INCLUDING SKILLS.** The user can always select "None" to skip.
   Excluding a useful skill = missed opportunity. Including an unnecessary skill = minor inconvenience.

- **DO NOT rationalize exclusions.** If a skill is even tangentially related, INCLUDE IT.
- Match on **related concepts**, not just exact matches
- Consider the **full workflow** the user might need, not just the immediate ask

**Examples - notice how INCLUSIVE these are:**
| User prompt | Matches (be generous!) |
|-------------|----------------------|
| "find unused packages" | code-reviewer, dependency-management, legacy-modernizer |
| "add a button" | brainstorming, TDD, frontend-developer, ui-ux-designer |
| "why is this slow" | systematic-debugging, performance-engineer, database-optimizer |
| "refactor this" | code-reviewer, legacy-modernizer, architect-review |
| "write tests" | TDD, test-automator, code-reviewer |

**Anti-pattern - DO NOT DO THIS:**
```
Matches: none (code-reviewer is for code quality, not dependency analysis)
         ^^^^^ THIS IS RATIONALIZING EXCLUSION - WRONG!
```

**Correct pattern:**
```
Matches: code-reviewer (could help analyze dependencies), dependency-management (related)
         ^^^^^ INCLUSIVE - let user decide if relevant
```

**Output this block for action requests:**
```
**Skill Analysis**
- Intent: [what user actually needs]
- Matches: [skill/agent names + why they match, or "none"]
- Recommendation: [skill(s)/agent(s) to use, or NONE]
```

**Then either:**
- **Matches found** → MUST use `AskUserQuestion` tool:

  **Single match:**
  ```
  Question: "How would you like to proceed?"
  Header: "Approach"
  Options:
    1. Label: "Use [skill-name]"
       Description: "[what it does]"
    2. Label: "None"
       Description: "Proceed without skills/agents"
  ```

  **Multiple matches (2 or more):** You MUST use `multiSelect: true` so user can pick any combination:
  ```
  Question: "Which skills/agents do you want to use?"
  Header: "Skills"
  multiSelect: true
  Options: (see FORMATTING RULES below for 1-2 vs 3+ matches)
  ```

  **Note:** "Use all" is first so user can press Enter to accept all.

  **IMPORTANT:** Count your matches. If Matches has 2+ items → MUST use multiSelect.

  **FORMATTING RULES (max 4 options allowed by tool):**

  **1-2 matches:** Show each individually
  ```
  1. "Use all" → skill1 + skill2
  2. "skill1" → description
  3. "skill2" → description
  4. "None" → Proceed without skills/agents
  ```

  **3+ matches:** Your recommendation becomes an option
  ```
  1. "Use all" → list ALL matches
  2. "Suggested" → YOUR specific recommendation from analysis
  3. "[alternative grouping]" → other useful combination
  4. "None" → Proceed without skills/agents
  ```

  **Example:** Matches: ui-ux, mobile, code-reviewer, performance (4 total)
            Recommendation: ui-ux + mobile (2 of 4)
            Remaining: code-reviewer, performance (2 of 4)
  ```
  1. "Use all" → ui-ux + mobile + code-reviewer + performance (4)
  2. "Suggested" → ui-ux + mobile (Claude's pick)
  3. "Technical" → code-reviewer + performance (the remaining!)
  4. "None" → Proceed without skills/agents
  ```
  ✓ Suggested (2) + Technical (2) = Use all (4) ← math checks out

  **Option naming:**
  - "Use all" = every matched skill/agent
  - "Suggested" = Claude's specific recommendation
  - "None" = skip skills, proceed directly (was "Manual")

  **Rules:**
  - **CRITICAL:** "Use all" MUST list EVERY match - count them!
  - Your "Recommendation" from analysis MUST appear as "Suggested" option
  - Option 3 = skills NOT in "Suggested" (the remaining ones!)
  - Option 4 = "None" (only option that skips skills)

  **NEVER duplicate meanings:**
  - If option 3 means "skip skills", you're doing it WRONG
  - Option 3 must offer skills that aren't in "Suggested"

  **Verification:**
  - Count: Use all items = total matches
  - Check: Suggested + Option 3 covers all matches
  - Confirm: Only "None" skips skills

  User can always select "Other" to type a custom response.

- **No matches** → Proceed directly (still show analysis block)

**⚠️ CRITICAL:** When skills are recommended, you MUST use `AskUserQuestion` tool.
Do NOT just write "Proceed?" as text. The tool creates a **blocking checkpoint**
that prevents you from ignoring your own recommendations. Text questions can be
ignored; tool-based questions cannot.

**⚠️ NO SELF-OVERRIDE:** If you found ANY matches (even weak ones), you MUST use
`AskUserQuestion`. You are NOT allowed to decide "this is simple, I'll skip the
checkpoint." That decision belongs to the USER, not you. Invalid rationalizations:
- "This is straightforward" → Still use checkpoint
- "I'll analyze directly" → Still use checkpoint
- "Not a primary fit" → Still use checkpoint
- "I know what to do" → Still use checkpoint
- "I'll only recommend one" → NO! Show ALL matches

The ONLY way to skip the checkpoint is if Matches = "none".

**⚠️ MULTISELECT RULE:** Count the items in your Matches list.
- 1 match → single select (Use [skill-name] / None)
- 2+ matches → MUST use `multiSelect: true` with ALL matches as options
- You are NOT allowed to filter matches down to 1. Show them ALL.
- If you show only 1 option when you found 2+ matches, you are BREAKING this rule.

**After user responds:**
| User selection | Your action |
|----------------|-------------|
| "Use all" / "Suggested" / selected skills | Immediately invoke the selected skills/agents |
| "None" | Proceed without skills/agents (user's explicit choice) |
| "Other" (custom) | Follow user's custom instruction |

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

[AskUserQuestion tool]
┌─────────────────────────────────────────┐
│ How would you like to proceed?          │
│                                         │
│ ○ Use requesting-code-review            │
│   Reviews implementation quality        │
│                                         │
│ ○ None                                  │
│   Proceed without skills/agents         │
└─────────────────────────────────────────┘

→ User selects "Use requesting-code-review"
→ Claude activates: Skill(superpowers:requesting-code-review)
```

**Multiple skills/agents (multiSelect):**
```
User: "improve the dashboard"

**Skill Analysis**
- Intent: design + implement improvements
- Matches:
  - brainstorming (explore ideas first)
  - ui-ux-designer (interface improvements)
  - mobile-developer (React Native patterns)
  - code-reviewer (code quality)
- Recommendation: brainstorming → ui-ux-designer + mobile-developer

[AskUserQuestion tool with multiSelect: true]
┌─────────────────────────────────────────┐
│ Which skills/agents do you want to use? │
│                                         │
│ ☐ Use all                               │
│   brainstorming + ui-ux + mobile +      │
│   code-reviewer (4)                     │
│                                         │
│ ☐ Suggested                             │
│   brainstorming → ui-ux + mobile (3)    │
│                                         │
│ ☐ Code quality                          │
│   code-reviewer (the remaining 1)       │
│                                         │
│ ☐ None                                  │
│   Proceed without skills/agents         │
└─────────────────────────────────────────┘

→ Suggested (3) + Code quality (1) = Use all (4) ✓
→ User selects "Suggested"
→ Claude activates in priority order:
   1. Skill(superpowers:brainstorming)
   2. Task(ui-ux-designer) + Task(mobile-developer)
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

### Multiple Skills Priority

When multiple skills match, follow priority order:

```
1. brainstorming         (design before code)
2. systematic-debugging  (fix before build)
3. test-driven-development
4. requesting-code-review
5. verification-before-completion
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

### Context7

When writing code or using library APIs:
- Auto-use Context7 MCP tools to fetch documentation
- Separate from skill routing — do both when applicable

---

## QUICK REFERENCE

```
EVERY PROMPT:
  1. Understand intent (semantic, not keywords)
  2. Match against skills (from memory)
  3. Output **Skill Analysis** block
  4. If ANY matches → AskUserQuestion (mandatory!)
  5. If no matches → proceed directly

FIRST PROMPT / AFTER COMPACT (only):
  Read once, remember for session:
  - ~/.claude/skill-catalog.yaml
  - ~/.claude/projects/{name}.yaml (if exists)

USER CHECKPOINT (when ANY skills match):
  Single match:  "Use [skill-name]" / "None"
  Multi match:   "Use all" / "Suggested" / [alternative] / "None"
  ⚠️ MUST use tool, not text question!
  ⚠️ NO self-override - user decides!

ACTIVATION:
  Skills:  Skill(superpowers:name) or Skill(plugin:name)
  Agents:  Task tool → subagent_type: "agent-name"

PRIORITY ORDER:
  brainstorming → debugging → TDD → review → verification

COMMANDS:
  claude-update-plugins    - Update plugins + regenerate catalog
  claude-refresh-project   - Regenerate current project profile
```
