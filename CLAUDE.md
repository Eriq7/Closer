# Development & Planning Protocol

## 1. Planning Hierarchy (Rolling Wave Planning)
- **Macro Plan**: At project start, define 3-5 high-level phases in `PLAN.md`.
- **Micro Detail**: Only provide detailed, step-by-step tasks for the **CURRENT** phase. Do not over-engineer future phases.
- **Phase Transition**: When a phase ends, update `PLAN.md` with ✅ and then detail the next phase by **expanding its tasks in-place** within `PLAN.md`, replacing the previous high-level description. `PLAN.md` is the single source of truth for all planning.
- **Dynamic Scope**: 
    - **Bug Fixes/Refactor**: Skip `PLAN.md` updates.
    - **New Features**: Append to `PLAN.md` chronologically before implementation with descrition

## 2. Checkpoint & Manual Verification (Crucial)
- **Manual Checklist**: Before starting any phase, generate a specific **Manual Verification Checklist** for the user (瑞).
  - This is NOT for automated tests.
  - It's for manual UI/UX checks and business logic flow (e.g., "Manually verify if the toast notification appears after saving").
- **🔍 CHECKPOINT**: Stop immediately at the end of every phase.
- **Mandatory Pause**: Summarize work done, present the Manual Checklist, and WAIT for "瑞" to approve before proceeding to any next steps.

## 3. Implementation & Context Rules
- **Module READMEs**: In major directories (e.g. `src/lib/`, `src/api/`), explain:
  1. **Responsibility**: Overall role of the module.
  2. **Data Flow**: Relationship between files and data direction.
  3. **Visuals**: Architecture diagrams or flowcharts (ASCII/Mermaid).
  4. **Decisions**: Explanations of key design choices.
- **File Headers**: Start every source file with a comment block including:
  1. **Summary**: One-sentence purpose.
  2. **Exports/IO**: Key functions/classes and their data types.
  3. **Execution Flow**: Step-by-step logic (e.g., Init -> Listen -> Cleanup).
  4. **Design Notes**: Rationale and specific technical constraints.
- **Test First**: Business logic must have corresponding plans in `TESTS.md`. Run all tests before any checkpoint.

## 4. Communication
- Always address the user as "**瑞**" at the start of every reply.
- Stay concise. Focus on "Action + Object + Result".