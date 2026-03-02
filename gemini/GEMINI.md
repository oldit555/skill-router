## Global AI Instructions
- **SMART SKILL ROUTING (PROTOCOL):**
  - **1. EVALUATE INTENT (NO DISCOVERY ALLOWED):** Upon receiving a new prompt, evaluate the SCOPE of the task. **You must perform this evaluation based ONLY on the user's initial prompt. You are strictly forbidden from using any search, file-reading, or execution tools until the Skill Routing checkpoint is complete.**
    - *Simple Tasks:* Factual questions, typo fixes, quick directory listings, or targeted edits strictly isolated to a single file. For these, proceed directly using standard tools.
    - *Complex Tasks:* Multi-file changes, debugging, architecture, refactoring, or ambiguous requests. For these, you MUST perform Skill Routing BEFORE using discovery/execution tools.
  - **2. ANALYSIS PHASE:** For Complex Tasks, output a '**Skill Analysis**' block formatted exactly as follows:
    - *Intent:* [What the user actually needs]
    - *Matches:* [List all relevant Agents/Skills and why. Err on the side of inclusion.]
    - *Recommendation:* [The single best Agent or Skill, OR a proposed combination.]
  - **3. USER CHECKPOINT:** Immediately after the Analysis block, you MUST use the ask_user tool (type: "choice") to present a menu.
    - **CRITICAL:** The tool strictly limits you to exactly 4 options. You must construct them like this:
      1. **Agent Only:** Delegate to your top recommended Agent.
      2. **Skill Only:** Activate your top recommended Skill (you will do the work yourself guided by the skill).
      3. **Synergy (Agent + Skill):** Combine them. You will activate the Skill, learn its rules, and use them to instruct the Agent.
      4. **Manual:** Proceed directly without loading any special agents or skills.
  - **4. NO SELF-OVERRIDE:** Never skip the checkpoint for complex tasks. The routing decision belongs to the user.
  - **5. STRICT DELEGATION:** Obey the user's choice. If they select 'Synergy', you must call activate_skill first, wait for the response, and then use that knowledge to formulate the prompt for the sub-agent. Do not perform the work directly unless 'Manual' or 'Skill Only' is selected.
