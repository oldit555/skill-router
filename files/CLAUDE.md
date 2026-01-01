# ~/.claude/CLAUDE.md

## SKILL ROUTER

### 🛑 MANDATORY: Skill Analysis on EVERY Prompt

**DEFAULT: Do skill analysis.** Skip is the rare exception.

**On EVERY prompt, before responding:**
1. **Understand intent** — What does the user actually need?
2. **Spawn/resume sonnet** → get skill matches
3. **Output Skill Analysis block** — Show your work
4. **If matches → AskUserQuestion** — User decides
5. **THEN proceed** — Execute selected skills or work directly

**Skip ONLY for:**
- Single-concept definitions ("what is X?") with NO images
- User said "skip" / "no skills"
- Already inside a skill

**Heuristic:** Specialist could help? → Analyze. When in doubt → Analyze.

**No exceptions. User decides via checkpoint, not you.** (See NO SELF-OVERRIDE for rationalization table)

---

### Sonnet Matching

**First prompt:** Spawn NEW sonnet agent:
```
Task(
  subagent_type: "general-purpose",
  model: "sonnet",
  prompt: "SKILL MATCHER - Analyze project and match skills. Save everything to memory.

           🛑 CONSTRAINTS:
           - You are ONLY a skill matcher - DO NOT execute commands, make changes, or act
           - ONLY use Read tool to read files, ONLY return JSON at the end
           - If unsure, return matches - NEVER act

           PHASE 1 - READ: ~/.claude/skill-catalog.yaml, ~/.claude/projects/{project-name}.yaml
           PHASE 2 - SCAN PROJECT: package.json, tsconfig.json, key source files (~30 sec max)
           PHASE 3 - MATCH: Analyze prompt, match skills using project context, apply skill_boosts
           PHASE 4 - ORDER: Determine execution order, group parallel skills

           EXECUTION ORDER: Understand before act → Design if new → Review last → Group independent

           MATCHING RULES:
           - Match on INTENT (what user wants to do), not SUBJECT (what they mention)
           - Subject not found in project? Still match based on intent - clarification comes later
           - Use FULL format: source:skill-name (exactly as in catalog)
           - When in doubt, MATCH (user can select None)

           SKIP ONLY for: typo fixes, simple renames, user said 'skip/no skills', single-concept definitions
           ALWAYS MATCH for: implementation, design/UX, architecture, multi-step, debugging, refactoring
           🛑 ANY image/screenshot = ALWAYS MATCH (no exceptions)

           User prompt: {USER_PROMPT}

           Return ONLY JSON:
           {
             \"project_summary\": \"brief\",
             \"matches\": [{\"name\": \"source:skill-name\", \"reason\": \"why\"}],
             \"recommendation\": \"skill1 + skill2\",
             \"execution_order\": [
               {\"phase\": 1, \"skills\": [\"skill-a\"], \"parallel\": false, \"reason\": \"why\"},
               {\"phase\": 2, \"skills\": [\"skill-b\", \"skill-c\"], \"parallel\": true, \"reason\": \"why\"}
             ]
           }"
)
```
**Save the returned `agent_id` for resuming.**

**Subsequent prompts:** RESUME sonnet:
```
Task(
  subagent_type: "general-purpose",
  model: "sonnet",
  resume: "{SONNET_AGENT_ID}",
  prompt: "Match new prompt. Use memory (no file reads). DO NOT use Read tool.

           Match on INTENT (what user wants), not SUBJECT (what they mention).
           Subject not found? Still match on intent - clarification comes later.

           SKIP ONLY for: typos, renames, user said 'skip/no skills', single-concept definitions
           ALWAYS MATCH for: implementation, design/UX, architecture, multi-step, debugging, refactoring
           🛑 ANY image/screenshot = ALWAYS MATCH (no exceptions)
           When in doubt, MATCH. User can select None.

           User prompt: {USER_PROMPT}
           Return JSON (USE FULL source:skill-name format):
           {matches: [{name: 'source:skill-name', reason}], recommendation, execution_order}"
)
```

**Placeholders:** `{USER_PROMPT}` = user's prompt, `{SONNET_AGENT_ID}` = agent_id from spawn, `{project-name}` = current directory name

**After conversation compact:** Spawn NEW sonnet (agent_id lost).

**Detect compact:** "This session is being continued..." or you don't remember agent_id.

---

### Matching Guidance

**Be INCLUSIVE, not conservative:**

⚠️ **ERR ON THE SIDE OF INCLUDING SKILLS.** User can always select "None".
- Excluding useful skill = missed opportunity
- Including unnecessary skill = minor inconvenience
- **DO NOT rationalize exclusions** - if tangentially related, INCLUDE IT

**Examples (be generous!):**
| User prompt | Matches (ALWAYS use full source:skill-name) |
|-------------|---------------------------------------------|
| "find unused packages" | code-refactoring:code-reviewer, dependency-management:..., etc |
| "add a button" | superpowers:brainstorming, superpowers:TDD, multi-platform-apps:ui-ux-designer |
| "why is this slow" | superpowers:systematic-debugging, application-performance:performance-engineer |
| "refactor this" | code-refactoring:code-reviewer, framework-migration:legacy-modernizer |

**Anti-pattern - DO NOT DO THIS:**
```
Matches: none (code-reviewer is for code quality, not dependency analysis)
         ^^^^^ THIS IS RATIONALIZING EXCLUSION - WRONG!
```

**Output format:**
```
**Skill Analysis**
- Intent: [what user actually needs]
- Matches: [skill/agent names + why, or "none"]
- Recommendation: [skill(s) to use, or NONE]
```

---

### Checkpoint Patterns

**Matches found → MUST use `AskUserQuestion` tool:**

**1 match:** 2 options
```
○ Use [skill-name] - [what it does]
○ None - Proceed without skills
```

**2 matches:** 4 options
```
○ Use all → skill1 + skill2
○ skill1 → description
○ skill2 → description
○ None → Proceed without skills
```

**3+ matches:** Grouped options
```
○ Use all → list ALL matches (count them!)
○ Suggested → YOUR recommendation from analysis
○ [alternative] → remaining skills NOT in Suggested
○ None → Proceed without skills
```

**Rules:**
- "Use all" MUST list EVERY match
- "Suggested" = your recommendation
- Option 3 = skills NOT in Suggested (the remaining ones)
- Suggested + Option 3 = Use all (verify math!)
- Only "None" skips skills

**No matches → Proceed directly** (still show analysis block)

---

### ⚠️ NO SELF-OVERRIDE

**If you found ANY matches (even weak ones), you MUST use `AskUserQuestion`.**

You are NOT allowed to decide "this is simple, I'll skip the checkpoint."
That decision belongs to the USER, not you.

**Invalid rationalizations:**
- "This looks simple" → Still do skill analysis
- "This is straightforward" → Still use checkpoint
- "I know what to do" → Still analyze + checkpoint
- "Just a quick command" → Still analyze
- "I'll analyze directly" → Still use checkpoint
- "Not a primary fit" → Still include in matches
- "I'll only recommend one" → NO! Show ALL matches

**The ONLY way to skip checkpoint is if Matches = "none".**

**GROUPING RULE:**
- 1 match → 2 options
- 2 matches → 4 options
- 3+ matches → 4 grouped options
- You are NOT allowed to filter matches down to 1. Show them ALL.

**After user responds:**
| Selection | Action |
|-----------|--------|
| Any with skills/agents | **IMMEDIATELY** invoke via `Skill()` or `Task()` |
| None | Proceed without skills (user's choice) |
| Custom | Follow user's instruction |

---

### Example

```
User: "improve the dashboard"

**Skill Analysis**
- Intent: design + implement improvements
- Matches: superpowers:brainstorming, multi-platform-apps:ui-ux-designer,
           multi-platform-apps:mobile-developer, code-refactoring:code-reviewer
- Recommendation: brainstorming → ui-ux-designer + mobile-developer

[AskUserQuestion]
○ Use all → all 4 skills
○ Suggested → brainstorming → ui-ux + mobile (3)
○ Code quality → code-reviewer (1)
○ None → Proceed without skills

→ User selects "Suggested"
→ Claude activates (using FULL names from matches):
   1. Skill(superpowers:brainstorming)
   2. Task(multi-platform-apps:ui-ux-designer) + Task(multi-platform-apps:mobile-developer)
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

### Skill Execution Plan

**When user selects skills → IMMEDIATELY create execution plan with TodoWrite.**

**TodoWrite is your memory. Without it, you WILL forget remaining skills.**

**Steps:**
1. Use Sonnet's `execution_order` from JSON
2. Write to TodoWrite: `☐ Phase 1: skill-a` / `☐ Phase 2: skill-b + skill-c (parallel)`
3. Show brief plan: `Execution: skill-a → skill-b + skill-c (parallel)`
4. Execute phase by phase, marking todos complete
5. For parallel phases: spawn ALL in one message
6. Only finish when ALL todos completed

**NEVER:**
- Skip writing todos ("I'll remember") — you won't
- Run first skill then forget the rest
- Do work manually instead of using selected agents
- Finish without checking all todos are complete
- Say "I'll use X later" — activate NOW or don't commit

**Verification:** Check todo list before completing. All done? Continue. Some pending? STOP and run them.

---

### Multi-Task Agent Selection

When executing plan with multiple tasks, ask ONCE at start:
```
How should I handle agent selection per task?
○ Auto-match specialists (Recommended)
○ Ask me each time
```

**Auto-match:** Show full mapping upfront → user approves → proceed automatically per task.

**Ask each time:** Checkpoint per task → user picks agent.

---

### Activation Syntax

| Type | Syntax |
|------|--------|
| Skill | `Skill(source:skill-name)` |
| Agent | `Task` tool with `subagent_type: "source:agent-name"` |

**⚠️ ALWAYS use FULL names from catalog (short names cause errors!):**
```
❌ /ui-ux-designer                    → Error: Unknown skill
❌ Skill(mobile-developer)            → Error: Unknown skill
✅ Skill(multi-platform-apps:ui-ux-designer)
✅ Task(..., subagent_type: "multi-platform-apps:mobile-developer")
```
**Sonnet returns full names. Use them exactly as returned.**

---

### User Override

| User says | Action |
|-----------|--------|
| "skip" / "no skills" | Proceed without activating |
| "use X instead" | Activate X, remember preference |
| "stop" (mid-skill) | Exit skill, continue task |

---

## QUICK REFERENCE

```
EVERY PROMPT (default = analyze, skip is rare exception):
  1. Understand intent → spawn/resume sonnet → get matches
  2. Output **Skill Analysis** block
  3. If matches → AskUserQuestion (mandatory!)
  4. THEN proceed with selected skills
  Skip ONLY: single-concept definitions, typos, user said skip
  🛑 ANY image = ALWAYS analyze (no exceptions)
  Heuristic: specialist could help? → analyze

SONNET AGENT:
  First prompt → spawn NEW sonnet (analyzes project + catalog)
  Subsequent  → RESUME sonnet (uses memory, fast)
  After compact → spawn NEW sonnet (re-analyze)

USER CHECKPOINT (when ANY skills match):
  Single match:  "Use [skill-name]" / "None"
  Multi match:   "Use all" / "Suggested" / [alternative] / "None"
  ⚠️ MUST use tool, not text question!
  ⚠️ NO self-override - user decides!
  ⚠️ Honor selections - use user's agents for actual work!

ACTIVATION (FULL names only - short names cause errors!):
  Skills:  Skill(source:skill-name)
  Agents:  Task tool → subagent_type: "source:agent-name"
  ❌ /ui-ux-designer → Error!
  ✅ Skill(multi-platform-apps:ui-ux-designer)

MULTI-SKILL EXECUTION:
  1. Use Sonnet's execution_order from JSON response
  2. Write each phase to TodoWrite immediately
  3. Show brief plan from execution_order
  4. Execute phase by phase, marking todos complete
  5. Parallel phases: spawn ALL in one message
  ⚠️ TodoWrite is your memory - without it you WILL forget
  ⚠️ NEVER finish without checking all todos complete

MULTI-TASK PLANS:
  Ask once: "Auto-match specialists" / "Ask me each time"
  Auto-match → show full mapping upfront → user approves → proceed
  Ask each time → checkpoint per task → user picks agent

COMMANDS:
  claude-update-plugins    - Update plugins + regenerate catalog
  claude-update-project    - Regenerate current project profile
```
