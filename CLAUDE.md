# CLAUDE.md

## 1. Planning — @PLAN.md is the Single Source of Truth
- If @PLAN.md does not exist, create it in the project root directory immediately.
- Before EVERY task, you MUST read @PLAN.md to understand current project state.
- When a phase is complete: mark it ✅, then expand the next phase into detailed sub-tasks in-place.
- When 瑞 describes a new feature: append it to @PLAN.md BEFORE writing any code.
- When something unplanned comes up during development: update @PLAN.md to reflect it.
- Bug fixes and refactors do NOT require @PLAN.md updates.

## 2. Task Breakdown & Gated Execution — NEVER Run Unbounded
When 瑞 gives you a feature to build:
1. **Decompose first** — Break it into logical sub-tasks (by sub-feature, NOT arbitrary splits). Present to 瑞:
   - Each sub-task's purpose
   - Execution order and dependencies
   - A verification checklist per sub-task (UI/UX flows + business logic, NOT automated tests)
2. **STOP and wait** — Do NOT write any code until 瑞 approves the breakdown.
3. **Execute one sub-task at a time** — After each sub-task, STOP and present:
   - What was done (Action + Object + Result)
   - Verification checklist for 瑞 to manually test
   - WAIT for 瑞's approval before continuing.
   - **Exception**: If two sub-tasks are tightly coupled (e.g., DB schema + its query layer), they MAY be executed together as one unit. Still STOP and present a combined checklist after.

NEVER execute a long plan end-to-end. NEVER skip a gate.

## 3. Code Standards
- **File Headers**: Core business logic files and complex modules MUST begin with a comment block:
  `Summary | Exports+IO | Execution Flow | Design Notes`
  Simple utility files, configs, and boilerplate do NOT need headers.
- **Module READMEs**: Only directories with non-obvious architecture MUST have a README:
  `Responsibility | Data Flow | Key Decisions`
- **Tests**: All business logic MUST have entries in @TESTS.md. Run all tests before every checkpoint.

## 4. Communication
- Address the user as **瑞** at the start of every response.
- Be concise: Action + Object + Result. No filler, no fluff.