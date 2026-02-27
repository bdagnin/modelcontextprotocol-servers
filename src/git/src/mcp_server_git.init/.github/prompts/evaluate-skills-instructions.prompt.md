---
name: Evaluate Skills and Instructions
description: Audit all skill and instruction files and migrate any that are incorrectly implemented as one type when they should be the other.
mode: agent
---

# Evaluate Skills vs. Instructions Placement

Audit all agent skill files (`.agents/skills/**/SKILL.md`) and instruction files (`.github/instructions/*.instructions.md`) in this workspace. Detect any that are incorrectly implemented as one type when they should be the other, and automatically correct them.

## Reference

Before starting, read the implementation guidance in [ABOUT.skills.md](ABOUT.skills.md) for the latest rules on when to use skills vs. instructions. Use that document as the authoritative source for classification criteria.

## Evaluation Procedure

### 1. Inventory

Scan and list every:
- Skill file: `.agents/skills/**/SKILL.md`
- Instruction file: `.github/instructions/*.instructions.md`

For each file, note its **name**, **description**, and **approximate line count**.

### 2. Classify Each File

Apply these decision criteria (from ABOUT.skills.md) to each file:

**Should be an AMBIENT INSTRUCTION** (`.github/instructions/`) if it is:
- A passive behavior that should always be active (e.g., coding style, commit conventions, tool preferences)
- Short enough that the context cost of always-loading is negligible (roughly under 50 lines of content)
- Needed on nearly every interaction of its type (e.g., every git commit, every code review)
- A simple rule set without complex workflow steps or reference documentation

**Should be an ON-DEMAND SKILL** (`.agents/skills/`) if it is:
- Detailed reference or workflow documentation loaded only when performing specific complex tasks
- Longer content where always-loading would waste context (roughly over 50 lines)
- Task-specific procedures invoked infrequently (e.g., release workflows, audit checklists)
- Content with extensive examples or step-by-step guides

**Consider a HYBRID approach** when content has both aspects:
- Create a lightweight ambient instruction with the essential rules (always loaded)
- Keep a heavier skill file with detailed reference material (loaded on demand)
- The ambient instruction should reference the skill file for deeper guidance

### 3. Report Findings

For each file, produce a classification:

| File | Current Type | Recommended Type | Reason | Action |
|------|-------------|-----------------|--------|--------|
| ... | Skill / Instruction | Skill / Instruction / Hybrid | Brief rationale | Keep / Migrate / Split |

### 4. Execute Migrations

For files that need migration:

#### Skill → Ambient Instruction
1. Inline the skill content into a new or existing `.github/instructions/*.instructions.md` file
2. Add proper frontmatter: `name`, `description`, `applyTo: "**/*"`
3. Delete the original skill directory
4. Update any instruction files that previously pointed to the deleted skill

#### Ambient Instruction → On-Demand Skill
1. Create a new skill directory: `.agents/skills/<skill-name>/SKILL.md`
2. Add proper frontmatter: `name`, `description`
3. Remove the content from the ambient instruction file (or replace with a lightweight pointer)
4. If the ambient instruction file becomes empty, delete it

#### Split into Hybrid
1. Extract the short, always-needed rules into the ambient instruction
2. Keep the detailed reference material in the skill file
3. Add a cross-reference link from the instruction to the skill

### 5. Validate

After all migrations:
- Verify no orphaned skill references exist in instruction files
- Verify no deleted skill directories are still referenced
- Confirm the remaining structure matches the guidance in ABOUT.skills.md

### 6. Commit

Stage and commit all changes with a descriptive message explaining what was migrated and why.
