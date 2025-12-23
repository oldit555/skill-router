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
2. **Get skill matches** — Spawn haiku (first prompt) or resume haiku (subsequent prompts)
3. **Output visible analysis** — Show your work (format below)
4. **Checkpoint or proceed** — If ANY matches, ask user; if none, proceed

**Skill matching (token-optimized with haiku):**

- **First prompt of session:** Spawn NEW haiku agent to analyze project and match:
  ```
  Task(
    subagent_type: "general-purpose",
    model: "haiku",
    prompt: "SKILL MATCHER - Analyze project and match skills. Save everything to memory.

             PHASE 1 - READ SKILL DATA:
             1. Read ~/.claude/skill-catalog.yaml
             2. Read ~/.claude/projects/{project-name}.yaml (if exists)

             PHASE 2 - ANALYZE PROJECT (quick scan, ~30 seconds max):
             3. Read package.json, tsconfig.json, or equivalent config files
             4. Scan a few key source files to understand patterns
             5. Note: framework, language, architecture style, testing approach
             6. STOP after understanding the project - don't analyze everything

             PHASE 3 - MATCH AND RETURN:
             7. Match user prompt against skills using project context
             8. Apply skill_boosts from profile if present
             9. Return JSON

             MATCHING RULES:
             - Use your project understanding to match better
             - Consider the full workflow user might need
             - When in doubt, MATCH (user can select None)

             SKIP MATCHING (return empty) ONLY for:
             - Literal typo fixes ("fix typo in X")
             - Simple renames ("rename X to Y")
             - User explicitly says 'quick', 'just', 'no skills'
             - Factual questions ("what does useEffect do?")

             NEVER SKIP - always find matches for:
             - ANY implementation task (needs TDD, developer agents)
             - ANY design/UX question (needs designer agents)
             - "How should I..." / "What's the best way..." (needs expertise)
             - Requests with images/screenshots (needs visual analysis)
             - Layout, organization, architecture questions
             - Multi-step work or feature building
             - Debugging or fixing issues

             User prompt: {USER_PROMPT}

             Return ONLY this JSON:
             {
               \"project_summary\": \"brief: framework, lang, type\",
               \"matches\": [{\"name\": \"skill-name\", \"reason\": \"why, given project context\"}],
               \"recommendation\": \"skill1 + skill2\"
             }"
  )
  ```
  **IMPORTANT:** Save the returned `agent_id` - you'll resume this agent later.

- **Subsequent prompts:** RESUME haiku (it has project context + catalog in memory):
  ```
  Task(
    subagent_type: "general-purpose",
    model: "haiku",
    resume: "{HAIKU_AGENT_ID}",
    prompt: "New prompt to match. Use your memory of the project and skill catalog.

             DO NOT re-read files. Just match from memory.

             SKIP ONLY for: typos, renames, 'quick/just/no skills'

             ALWAYS MATCH for:
             - Implementation tasks → TDD + developer agents
             - Design/UX questions → designer agents
             - 'How should I...' → expertise needed
             - Images/screenshots → visual analysis
             - Any multi-step work

             When in doubt, MATCH. User can select None.

             User prompt: {USER_PROMPT}

             Return ONLY: {\"matches\": [...], \"recommendation\": \"...\"}"
  )
  ```
  Fast - no file reads, uses memory of project + catalog.

- **After conversation compact:** Spawn NEW haiku (lost the agent_id, need fresh analysis).

**Placeholders to replace:**
- `{USER_PROMPT}` → actual user prompt
- `{project-name}` → project name from current directory
- `{HAIKU_AGENT_ID}` → agent_id from previous haiku spawn

**How to detect compact/memory loss:**
- You see "This session is being continued from a previous conversation..."
- You don't remember the haiku agent_id
- You're unsure if you have a haiku agent to resume

**When in doubt:** Spawn new haiku. The first-prompt analysis is worth it for better matching.

**Why haiku?** Analyzes project + reads catalog cheaply. Remembers context for the session. Main Claude stays focused on execution.

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

  **Multiple matches (2 or more):** Use grouped options (single select):
  ```
  Question: "Which skills/agents do you want to use?"
  Header: "Skills"
  Options: (see FORMATTING RULES below for 1-2 vs 3+ matches)
  ```

  **Note:** "Use all" is first so user can press Enter to accept all.
  Options are already grouped - user picks ONE group, not individual skills.

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

  **If recommendation = ALL matches (no remaining):**
  Skip "Use all" (redundant). Restructure options:
  ```
  1. "Suggested" → your recommendation (which is all matches)
  2. "[subset 1]" → meaningful alternative (e.g., design only)
  3. "[subset 2]" → another alternative (e.g., implementation only)
  4. "None" → Proceed without skills/agents
  ```
  Example: Matches = brainstorming + TDD + mobile (3)
           Recommendation = all 3
  ```
  1. "Suggested" → brainstorming + TDD + mobile (full workflow)
  2. "Design first" → brainstorming only
  3. "Quick implementation" → mobile-developer only
  4. "None" → Proceed without skills/agents
  ```

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

**⚠️ GROUPING RULE:** Count the items in your Matches list.
- 1 match → 2 options (Use [skill-name] / None)
- 2+ matches → 4 grouped options (Use all / Suggested / [alternative] / None)
- You are NOT allowed to filter matches down to 1. Show them ALL in grouped options.
- User picks ONE group. Groups cover all matches.

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

**Multiple skills/agents (grouped options):**
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

[AskUserQuestion tool]
┌─────────────────────────────────────────┐
│ Which skills/agents do you want to use? │
│                                         │
│ ○ Use all                               │
│   brainstorming + ui-ux + mobile +      │
│   code-reviewer (4)                     │
│                                         │
│ ○ Suggested                             │
│   brainstorming → ui-ux + mobile (3)    │
│                                         │
│ ○ Code quality                          │
│   code-reviewer (the remaining 1)       │
│                                         │
│ ○ None                                  │
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

**After first skill completes → auto-continue with remaining selected skills.**
No need to ask again. User already chose at checkpoint.

```
User selects: brainstorming + ui-ux-designer + mobile-developer

1. Run brainstorming
2. When done → auto-invoke ui-ux-designer + mobile-developer
3. NO extra confirmation needed
```

---

### Honor User Selections

When user selects specific agents (ui-ux-designer, mobile-developer, etc.):
- These should be **USED during implementation**, not skipped
- Skill workflows (brainstorming → writing-plans) can still run
- But user's agents should do the actual work

**Example:**
```
User selects: brainstorming + ui-ux-designer + mobile-developer

✅ GOOD:
1. brainstorming runs (explores design)
2. writing-plans runs (skill's internal workflow - OK)
3. subagent-driven-development runs
4. ui-ux-designer + mobile-developer do the actual work ← DON'T FORGET THESE
```

**Before completing any task, ask yourself:**
"Did I actually use the agents the user selected?"

If not → invoke them before finishing.

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
| Skill | `Skill(source:skill-name)` |
| Agent | `Task` tool with `subagent_type: "source:agent-name"` |

**⚠️ ALWAYS use FULL names (source:name) from the catalog:**
```
❌ mobile-developer
✅ frontend-mobile-development:mobile-developer

❌ brainstorming
✅ superpowers:brainstorming
```

The skill catalog lists full names. Use them exactly as shown.

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
  2. Get matches from haiku (spawn or resume)
  3. Output **Skill Analysis** block
  4. If ANY matches → AskUserQuestion (mandatory!)
  5. If no matches → proceed directly

HAIKU AGENT:
  First prompt → spawn NEW haiku (analyzes project + catalog)
  Subsequent  → RESUME haiku (uses memory, fast)
  After compact → spawn NEW haiku (re-analyze)

USER CHECKPOINT (when ANY skills match):
  Single match:  "Use [skill-name]" / "None"
  Multi match:   "Use all" / "Suggested" / [alternative] / "None"
  ⚠️ MUST use tool, not text question!
  ⚠️ NO self-override - user decides!
  ⚠️ Honor selections - use user's agents for actual work!

ACTIVATION (use FULL names from catalog):
  Skills:  Skill(source:skill-name)
  Agents:  Task tool → subagent_type: "source:agent-name"
  Example: frontend-mobile-development:mobile-developer

PRIORITY ORDER:
  brainstorming → debugging → TDD → review → verification

MULTI-SKILL FLOW:
  First skill completes → auto-continue with remaining
  NO extra confirmation - user already chose

COMMANDS:
  claude-update-plugins    - Update plugins + regenerate catalog
  claude-refresh-project   - Regenerate current project profile
```
