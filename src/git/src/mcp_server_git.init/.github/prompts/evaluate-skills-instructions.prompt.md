---
name: Evaluate Skills and Instructions
description: Audit all skill and instruction files and migrate any that are incorrectly implemented as one type when they should be the other.
mode: agent
---

# Evaluate Skills vs. Instructions Placement

Audit all agent skill files and instruction files in this workspace. Detect any that are incorrectly implemented as one type when they should be the other, and automatically correct them.

## Reference

Before starting, read the implementation guidance in [ABOUT.skills.md](ABOUT.skills.md) for the latest rules on when to use skills vs. instructions. Use that document as the authoritative source for classification criteria.

## Evaluation Procedure

### 1. Inventory

Scan and list every skill and instruction file across all platform locations:

**Skills** (on-demand):
- `.agents/skills/**/SKILL.md`
- `.claude/skills/**/SKILL.md`
- `.github/skills/**/SKILL.md`

**Instructions** (ambient / always-on):
- `.agents/instructions/*.instructions.md`
- `.github/instructions/*.instructions.md`
- `.claude/rules/*.md`
- `AGENTS.md` (note contents but do not migrate the shim itself)
- `CLAUDE.md` (note contents but do not migrate platform shims)

For each file, note its **name**, **description**, **location**, and **approximate line count** of actual rule content (excluding frontmatter and headings).

### 2. Classify Each File

Apply these decision criteria (from ABOUT.skills.md) to each file:

**Should be an AMBIENT INSTRUCTION** if it is:
- A passive behavior that should always be active (e.g., coding style, commit conventions, tool preferences)
- Short enough that the context cost of always-loading is negligible (roughly under 50 lines of content)
- Needed on nearly every interaction of its type (e.g., every git commit, every code review)
- A simple rule set without complex workflow steps or reference documentation

**Should be an ON-DEMAND SKILL** if it is:
- Detailed reference or workflow documentation loaded only when performing specific complex tasks
- Longer content where always-loading would waste context (roughly over 50 lines)
- Task-specific procedures invoked infrequently (e.g., release workflows, audit checklists)
- Content with extensive examples or step-by-step guides

**Consider a HYBRID approach** when content has both aspects:
- Create a lightweight ambient instruction with the essential rules (always loaded)
- Keep a heavier skill file with detailed reference material (loaded on demand)
- The ambient instruction should reference the skill file for deeper guidance

### 3. Check Cross-Platform Placement

For each instruction file, verify it is in the recommended cross-platform location:
- **Preferred**: `.agents/instructions/` (platform-neutral, works with AGENTS.md shim and configurable native loading)
- **Acceptable**: Platform-specific locations (`.github/instructions/`, `.claude/rules/`) if there is a platform-specific reason (e.g., using `paths` glob in Claude Code rules)
- **Flag**: Files that exist only in a single-platform location when they should be cross-platform

For each skill file, verify:
- **Preferred**: `.agents/skills/` (broadest cross-platform compatibility)
- **Acceptable**: `.claude/skills/` if using Claude Code-specific features (`context: fork`, `model`, etc.)

### 4. Report Findings

For each file, produce a classification:

| File | Location | Current Type | Recommended Type | Cross-Platform? | Reason | Action |
|------|----------|-------------|-----------------|-----------------|--------|--------|
| ... | path | Skill / Instruction | Skill / Instruction / Hybrid | Yes / No (note) | Brief rationale | Keep / Migrate / Split / Move |

### 5. Execute Migrations

For files that need migration:

#### Skill → Ambient Instruction
1. Create a new `.agents/instructions/<name>.instructions.md` file with the content
2. Add proper frontmatter: `name`, `description`, `applyTo: "**/*"`
3. Delete the original skill directory
4. Update any files that previously referenced the deleted skill

#### Ambient Instruction → On-Demand Skill
1. Create a new skill directory: `.agents/skills/<skill-name>/SKILL.md`
2. Add proper frontmatter: `name` (lowercase-hyphenated, matching directory), `description`
3. Remove the content from the ambient instruction file (or replace with a lightweight cross-reference)
4. If the ambient instruction file becomes empty, delete it

#### Split into Hybrid
1. Extract the short, always-needed rules into a `.agents/instructions/<name>.instructions.md` module
2. Keep the detailed reference material in `.agents/skills/<skill-name>/SKILL.md`
3. Add a cross-reference link from the instruction to the skill

#### Move for Cross-Platform Compatibility
1. Move the file to the recommended cross-platform location (`.agents/instructions/` or `.agents/skills/`)
2. If a platform-specific copy is also needed, note it but prefer the shared location as canonical
3. Update any references to the old path

### 6. Validate

After all migrations:
- Verify no orphaned skill references exist in instruction files
- Verify no deleted skill directories are still referenced
- Confirm the remaining structure matches the guidance in ABOUT.skills.md
- Verify `AGENTS.md` shim (if present) correctly directs to `.agents/instructions/`

### 7. Commit

Stage and commit all changes with a descriptive message explaining what was migrated and why.
