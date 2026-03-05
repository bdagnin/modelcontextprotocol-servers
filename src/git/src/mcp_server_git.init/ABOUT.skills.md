# About This Directory: Agentic Skills and Instructions

This directory contains agent skill files (`SKILL.md`) and instruction files (`.instructions.md`) that define specialized capabilities for AI coding agents. These files are embedded into the init script and deployed to the target workspace root.

This document is the authoritative reference for deciding when to create a skill vs. an instruction, how to format each, and how to achieve cross-platform portability with modular opt-in/opt-out control.

## The Agent Skills Open Standard

Agent Skills is an [open standard](https://agentskills.io/) for giving AI agents new capabilities. The format is portable across multiple tools including VS Code (GitHub Copilot), Claude Code, GitHub Copilot CLI, Amp, Roo Code, and others.

Each skill is a self-contained directory with a `SKILL.md` entrypoint that agents discover, evaluate, and load on demand.

## Skills vs. Instructions: When to Use Each

The single most important decision is whether content should be **always loaded** (ambient instruction) or **loaded on demand** (skill). Getting this wrong wastes context budget or causes agents to miss critical rules.

### Always-On Instructions (Ambient)

**Mechanism**: Automatically loaded into every agent interaction. No tool calls needed. The full content is always in context.

**Platform locations**:

| Platform | Location | Format | Scope |
|----------|----------|--------|-------|
| **All platforms** | `AGENTS.md` (root or subdirs) | Plain markdown | Universal always-on |
| VS Code (Copilot) | `.github/instructions/*.instructions.md` | YAML frontmatter with `applyTo` glob | VS Code only |
| VS Code (Copilot) | `.github/copilot-instructions.md` | Plain markdown | VS Code only |
| Claude Code | `CLAUDE.md`, `.claude/CLAUDE.md` | Plain markdown with `@import` support | Claude Code only |
| Claude Code | `.claude/rules/*.md` | YAML frontmatter with `paths` glob | Claude Code only |
| Cursor | `.cursor/rules/*.md` or `.cursor/rules/*.mdc` | YAML frontmatter with `globs`/`alwaysApply` | Cursor only |
| Windsurf | `.windsurf/rules/*.md` | YAML frontmatter with activation modes | Windsurf only |

> **Cross-platform recommendation**: Use `AGENTS.md` for always-on instructions that must work across all AI ecosystems. It is supported by VS Code, Cursor, Windsurf, and Claude Code. Use platform-specific files (`.github/instructions/`, `.claude/rules/`, etc.) only when you need platform-specific features like glob-based scoping.

**Use for content that is**:
- A passive behavior that should always be active (coding style, commit conventions, tool preferences)
- Short enough that always-loading is negligible (~50 lines or fewer of actual rules)
- Needed on nearly every interaction of its type (e.g., every commit, every code review)
- Simple rule sets without complex workflows or extensive reference material

**Examples**: "Use imperative commit messages", "Prefer MCP tools over terminal", "Attribute commits to the AI agent"

### On-Demand Skills (Loaded When Relevant)

**Mechanism**: Agent reads only the `name` and `description` metadata at startup (~100 tokens per skill). Full instructions load only when the task matches. Supports progressive disclosure with supporting files.

> **Important distinction**: Only the skill **metadata** (name + description) is ambient — it is always in context so the agent knows the skill exists. The full skill body is **never** ambient — it only loads on invocation. For content that must always be fully in context, use an ambient instruction, not a skill.

**Platform locations** (all follow the [Agent Skills](https://agentskills.io/) open standard):

| Platform | Project Skills Location | Personal Skills Location |
|----------|----------------------|------------------------|
| VS Code (Copilot) | `.github/skills/`, `.agents/skills/`, `.claude/skills/` | `~/.copilot/skills/`, `~/.agents/skills/` |
| Claude Code | `.claude/skills/`, `.agents/skills/` | `~/.claude/skills/` |
| Cursor | `.agents/skills/` (via Agent Skills toggle in settings) | N/A |
| Windsurf | `.windsurf/skills/`, `.agents/skills/` | `~/.codeium/windsurf/skills/` |
| GitHub Copilot CLI | `.github/skills/`, `.agents/skills/` | N/A |

> **Cross-platform recommendation**: Place skills in `.agents/skills/` for broadest compatibility. This location is recognized by VS Code and follows the Agent Skills standard. For Claude Code-specific features (sub-agents, hooks, model selection), also consider `.claude/skills/`.

**Use for content that is**:
- Detailed reference or workflow documentation (diffing branches, release processes, audit checklists)
- Longer than ~50 lines where always-loading would waste context
- Task-specific procedures invoked infrequently
- Content with extensive examples, step-by-step guides, or supporting files (scripts, templates)

**Examples**: "Git MCP tool workflow reference", "PR review checklist", "Database migration procedure"

### Hybrid Approach (Recommended for Complex Topics)

When a topic has both short, always-needed rules AND detailed reference material:

1. **Create a lightweight ambient instruction** with the essential rules (always loaded, ~20-40 lines)
2. **Keep a skill file** with the detailed reference material (loaded on demand)
3. **Cross-reference**: The instruction links to the skill for deeper guidance

This optimizes for both context efficiency and completeness.

### Quick Decision Flowchart

    Is this content needed on nearly every interaction?
    |-- YES --> Is it under ~50 lines of actual rules?
    |           |-- YES --> Ambient instruction
    |           +-- NO  --> Hybrid: split into ambient rules + on-demand skill
    +-- NO  --> On-demand skill

## Modular Instruction Architecture (Preferred Pattern)

### The Cross-Platform Problem

Each AI platform has its own instruction mechanism (`.github/instructions/`, `.claude/rules/`, `.cursor/rules/`, `.windsurf/rules/`). Writing platform-specific files for each creates maintenance burden and makes it difficult for users to opt in or out of individual behaviors.

### Solution: Shared Modules with a Universal Shim

> **Note**: The modular instruction architecture described below (`.agents/instructions/` modules, `AGENTS.md` shim) is the recommended target pattern. This workspace currently uses `.github/instructions/` with `#file:` references as a transitional approach. The patterns documented here are forward-looking guidance for new projects and future migration.

This project uses a **modular instruction** pattern: shared instruction modules in a central location, with platform-native loading where available and `AGENTS.md` as a universal fallback.

> **Convention notice**: The `.agents/instructions/` directory is a **project convention** for cross-platform modularity. It is not part of the Agent Skills specification or any published standard (the Agent Skills standard defines `.agents/skills/` but not `.agents/instructions/`). This convention keeps instruction modules in a platform-neutral location while allowing each platform to load them through its own mechanism.

### Directory Structure

    workspace-root/
    ├── AGENTS.md                                  # Universal shim (always loaded by all platforms)
    ├── .agents/
    │   ├── instructions/                          # Shared modular instruction modules
    │   │   ├── git-attribution.instructions.md
    │   │   ├── commit-style.instructions.md
    │   │   └── prefer-mcp.instructions.md
    │   └── skills/                                # On-demand skills (Agent Skills standard)
    │       └── mcp-server-git/
    │           └── SKILL.md
    └── (platform-specific configuration as needed)

### How It Works: Tiered Loading

**Tier 1: Platform-Native Loading (reliable, preferred)**

Where a platform supports configuring custom instruction source locations, point it at `.agents/instructions/`. The platform loads modules automatically without tool calls — they behave exactly like built-in always-on instructions.

| Platform | Native Mechanism | Configuration |
|----------|-----------------|---------------|
| VS Code | `chat.instructionsFilesLocations` setting | Add `".agents/instructions": true` to workspace settings |
| Claude Code | `@import` syntax in `CLAUDE.md` | Add `@.agents/instructions/<module>.instructions.md` per module |

**Tier 2: AGENTS.md Soft Instruction (universal fallback)**

For platforms without configurable instruction source locations (or when Tier 1 is not configured), `AGENTS.md` acts as the entry point. Since `AGENTS.md` is loaded automatically by all major platforms, it can direct the agent to discover and read modules.

| Platform | How It Works |
|----------|--------------|
| Cursor | Reads `AGENTS.md`, agent follows directive to read module files |
| Windsurf | Same — `AGENTS.md` is loaded, agent reads modules via tools |
| Other agents | Any agent that supports `AGENTS.md` can follow the directive |

**Reliability note**: Tier 2 relies on the agent making tool calls (e.g., `list_dir`, `read_file`) to load instruction modules. This is less reliable than Tier 1 native loading because it depends on the model following the directive and its ability to access the file system. Always configure Tier 1 where available.

### AGENTS.md Shim Template

The root `AGENTS.md` should contain:

    # Workspace Agent Instructions

    ## Modular Instructions

    This workspace uses modular instruction files. On each interaction, read and
    apply all `.instructions.md` files from `.agents/instructions/`.

    Each file is an independent module covering one topic. List the directory to
    discover available modules, then read and apply all that match the current task.

    Modules use `.instructions.md` format with optional YAML frontmatter:
    - `name`: Display name for the module
    - `description`: When this module applies
    - `applyTo`: Glob pattern for file-scoped activation (VS Code native)

    ## Quick Reference

    [Include any critical rules here that MUST be seen even if module
    loading fails — keep this section minimal, under 10 lines.]

### Instruction Module Format

Each module is a self-contained `.instructions.md` file:

    ---
    name: Git Attribution
    description: Rules for attributing commits to the AI agent for traceability.
    applyTo: "**/*"
    ---
    # Git Attribution

    When committing changes, attribute them to your AI assistant identity...

The YAML frontmatter serves dual purposes:
- **VS Code**: `applyTo` enables native glob-based activation when loaded via `chat.instructionsFilesLocations`
- **All platforms**: `name` and `description` help agents understand the module's purpose

### User Modularity

The key benefit of this pattern is that users control which behaviors are active by managing files:

- **Remove a module**: Delete the `.instructions.md` file to disable that behavior
- **Add a module**: Drop a new `.instructions.md` file into `.agents/instructions/`
- **Review what's active**: `ls .agents/instructions/` shows all active modules at a glance
- **Share modules**: Individual files can be copied between projects
- **No editing required**: Adding or removing modules never requires editing `AGENTS.md` or any other file

### Platform-Native Configuration Details

**VS Code** — Add to `.vscode/settings.json`:

    {
      "chat.instructionsFilesLocations": {
        ".github/instructions": true,
        ".agents/instructions": true
      }
    }

VS Code scans the configured directories for `*.instructions.md` files and applies them based on their `applyTo` patterns — no shim or tool calls needed.

**Claude Code** — Add to `CLAUDE.md`:

    @.agents/instructions/git-attribution.instructions.md
    @.agents/instructions/commit-style.instructions.md

Each `@import` loads the module's content directly into context. Modules must be listed explicitly; Claude Code does not support directory-level wildcard imports.

## SKILL.md Format (Agent Skills Standard)

### Directory Structure

    skill-name/
    ├── SKILL.md           # Required entrypoint
    ├── references/        # Optional: detailed docs loaded on demand
    ├── scripts/           # Optional: executable scripts
    ├── assets/            # Optional: templates, schemas, data
    └── examples/          # Optional: example inputs/outputs

### Required Frontmatter

    ---
    name: skill-name          # Lowercase, hyphens only, max 64 chars, must match directory name
    description: >-           # Max 1024 chars. Describe WHAT and WHEN.
      Detailed description including keywords that help agents identify relevant tasks.
    ---

### Optional Frontmatter Fields

**Standard fields** (Agent Skills specification — portable across all platforms):

| Field | Purpose |
|-------|---------|
| `license` | License name or reference to bundled LICENSE file |
| `compatibility` | Environment requirements (e.g., "Requires git, docker"). Max 500 chars. |
| `metadata` | Arbitrary key-value pairs (author, version, etc.) |

**Platform-extended fields** (supported by specific platforms — non-portable):

| Field | Platform | Purpose |
|-------|----------|---------|
| `allowed-tools` | Claude Code, VS Code | Space-delimited list of pre-approved tools the skill may use |
| `argument-hint` | VS Code, Claude Code | Hint for slash command arguments (e.g., `[filename] [options]`) |
| `user-invocable` | Claude Code | `false` to hide from `/` menu; background knowledge only |
| `disable-model-invocation` | Claude Code, VS Code | `true` to prevent automatic invocation; manual `/` invocation only |
| `context` | Claude Code | `fork` to run in an isolated sub-agent |
| `model` | Claude Code | Model to use for this skill (e.g., `haiku` for fast operations) |

### Claude Code Skill Features

Claude Code extends the Agent Skills standard with several features not available on other platforms:

**Sub-agent execution**: Set `context: fork` to run the skill in an isolated sub-agent. Useful for research, analysis, or tasks that shouldn't pollute the main conversation's context.

**Dynamic context injection**: Use `` !`command` `` syntax in the SKILL.md body to run a shell command and inject its output into the skill's context when activated. For example, `` !`git status` `` injects the current git status.

**Parameterized skills**: Use `$ARGUMENTS` in the skill body to substitute user-provided arguments when invoked via `/skill-name arg1 arg2`. Use `$ARGUMENTS[0]`, `$ARGUMENTS[1]` for positional access.

**Model selection**: Use the `model` frontmatter field to specify which model runs the skill (e.g., `model: haiku` for fast, cheap operations).

**Invocation control**:
- Default: both user (`/skill-name`) and Claude (automatic when relevant) can invoke
- `disable-model-invocation: true`: user-only invocation; use for side-effect-heavy skills (deploy, commit, send)
- `user-invocable: false`: Claude-only invocation; use for background knowledge the agent should know about but users should not trigger directly

See [Claude Code: Skills](https://code.claude.com/docs/en/skills) for the full feature reference.

### Body Guidelines

- Keep `SKILL.md` **under 500 lines**. Move detailed reference material to separate files.
- Write clear, actionable instructions with concrete examples.
- Reference supporting files with relative paths: `[reference guide](references/REFERENCE.md)`
- The full body loads only when the skill is activated (~5000 tokens recommended max).

### Name Validation Rules

- Lowercase letters, numbers, and hyphens only (`a-z`, `0-9`, `-`)
- Must not start or end with `-`
- Must not contain consecutive hyphens (`--`)
- Must match the parent directory name exactly

## Instructions File Format (.instructions.md)

### VS Code Format

    ---
    name: Display Name
    description: Short description shown on hover
    applyTo: "**/*"          # Glob pattern; use ** for all files
    ---
    # Instructions content in Markdown

The `applyTo` glob controls when instructions activate. Use `**/*` for universal rules, or scope to specific file types (e.g., `**/*.py`). If omitted, instructions are not applied automatically.

### Claude Code Rules Format (.claude/rules/*.md)

    ---
    paths:
      - "src/**/*.ts"
      - "tests/**/*.test.ts"
    ---
    # Rules content in Markdown

Uses a `paths` array instead of `applyTo`. Defaults to all files when omitted.

## Progressive Disclosure (How Agents Load Content)

The Agent Skills standard defines a three-level loading system:

1. **Level 1 — Discovery** (~100 tokens): `name` and `description` from frontmatter are always loaded for all skills. This is the only part that is ambient.
2. **Level 2 — Instructions** (<5000 tokens recommended): The full `SKILL.md` body loads when the agent determines the skill is relevant or the user invokes it.
3. **Level 3 — Resources** (as needed): Supporting files (scripts, references, assets) load only when explicitly referenced during execution.

This means you can install many skills without consuming context. Only what's relevant loads.

> **Ambient instructions vs. skill metadata**: Do not confuse the ~100-token skill description (Level 1) with a full ambient instruction. Skill descriptions tell the agent a skill *exists*; ambient instructions provide *rules the agent follows on every interaction*. If a rule must always be applied, it belongs in an instruction, not a skill description.

## Cross-Platform Compatibility Notes

### Skills: Fully Portable

The Agent Skills standard (`SKILL.md` format) is the **only fully portable mechanism** across AI ecosystems. It works across VS Code, Claude Code, Cursor, Windsurf, GitHub Copilot CLI, Amp, Roo Code, and others. Write skills once, use everywhere.

### Always-On Instructions: Platform-Specific (Except AGENTS.md)

| Mechanism | VS Code | Claude Code | Cursor | Windsurf |
|-----------|:-------:|:-----------:|:------:|:--------:|
| `AGENTS.md` | Yes | Yes | Yes | Yes |
| `.github/instructions/*.instructions.md` | Yes | No | No | No |
| `.github/copilot-instructions.md` | Yes | No | No | No |
| `CLAUDE.md` / `.claude/rules/` | No | Yes | No | No |
| `.cursor/rules/` | No | No | Yes | No |
| `.windsurf/rules/` | No | No | No | Yes |

### Recommendations

- **For portable always-on instructions**: Use the modular instruction pattern — `AGENTS.md` shim + `.agents/instructions/*.instructions.md` modules. Configure platform-native loading (Tier 1) where available for reliability.
- **For portable on-demand capabilities**: Use Agent Skills (`SKILL.md`) in `.agents/skills/`.
- **For platform-native enhancement**: Configure `chat.instructionsFilesLocations` (VS Code) or `@import` (Claude Code) to load `.agents/instructions/` modules natively, eliminating the need for tool calls.
- **Prefer `.agents/` over `.github/`**: The `.agents/` namespace is agent-ecosystem neutral. `.github/instructions/` is VS Code-only and should not be the primary location for cross-platform content.
- **Avoid monolithic instruction files**: Do not put all rules in a single `AGENTS.md`. Break them into independent modules so users can enable/disable individual behaviors.

## Best Practices

- **Be specific**: Target a clear, narrow task per skill. One topic per instruction module.
- **One concern per module**: Each `.instructions.md` file should cover exactly one topic (e.g., attribution, commit style, tool preference). This enables granular user control.
- **Use examples**: Concrete good/bad examples are more effective than abstract rules.
- **Size-appropriate**: Short passive rules → instruction modules. Long reference material → skills.
- **Cross-reference**: Instruction modules should link to related skills for deeper guidance.
- **Keep SKILL.md focused**: Under 500 lines. Move detailed docs to `references/` subdirectory.
- **Descriptive filenames**: Use names like `git-attribution.instructions.md` — the filename should describe the behavior it controls.
- **Always include `applyTo`**: For universal instruction modules, set `applyTo: "**/*"` to enable VS Code native loading.
- **Keep AGENTS.md minimal**: The `AGENTS.md` shim should contain only the module-loading directive and a small critical-rules fallback. Actual rules belong in modules.
- **Iterate**: Refine based on agent performance. If an instruction is often ignored, it may need examples.
- **Evaluate regularly**: Use the [evaluation prompt](.github/prompts/evaluate-skills-instructions.prompt.md) to audit placement periodically.

## Design Guidelines for Modules

- **One topic per module**: Each file covers exactly one concern (attribution, commit style, tool preference, etc.)
- **Self-contained**: A module should make sense on its own, without requiring other modules
- **Short**: Each module should be under ~30 lines of actual rules. If longer, consider splitting or using a hybrid skill.
- **Descriptive filename**: The filename (e.g., `git-attribution.instructions.md`) should clearly indicate what the module controls
- **Include `applyTo`**: Always include `applyTo: "**/*"` for universal modules, or a specific glob for scoped ones, to enable VS Code native loading

## Reference Documentation

### Standards
- [Agent Skills Open Standard](https://agentskills.io/) — Portable specification
- [Agent Skills Specification](https://agentskills.io/specification) — Detailed format reference
- [Agent Skills Integration Guide](https://agentskills.io/integrate-skills) — How agents implement skills

### Platform Documentation
- [VS Code: Agent Skills](https://code.visualstudio.com/docs/copilot/customization/agent-skills) — VS Code integration
- [VS Code: Custom Instructions](https://code.visualstudio.com/docs/copilot/customization/custom-instructions) — Instruction file format
- [Claude Code: Skills](https://code.claude.com/docs/en/skills) — Claude Code skill features
- [Claude Code: Memory](https://code.claude.com/docs/en/memory) — CLAUDE.md and rules format
- [Cursor: Rules](https://cursor.com/docs/context/rules) — Cursor rules and Agent Skills import
- [Windsurf: Skills](https://docs.windsurf.com/windsurf/cascade/skills) — Windsurf skills support
- [Windsurf: Memories & Rules](https://docs.windsurf.com/windsurf/cascade/memories) — Windsurf rules format

### Examples
- [Example Skills Repository](https://github.com/anthropics/skills) — Reference implementations
- [Awesome Copilot](https://github.com/github/awesome-copilot) — Community examples
