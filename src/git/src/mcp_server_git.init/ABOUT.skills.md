# About This Directory: Agentic Skills and Instructions

This directory contains agent skill files (`SKILL.md`) and instruction files (`.instructions.md`) that define specialized capabilities for AI coding agents. These files are embedded into the init script and deployed to the target workspace root.

## The Agent Skills Open Standard

Agent Skills is an [open standard](https://agentskills.io/) for giving AI agents new capabilities. The format is portable across multiple tools including VS Code (GitHub Copilot), Claude Code, GitHub Copilot CLI, Amp, Roo Code, and others.

Each skill is a self-contained directory with a `SKILL.md` entrypoint that agents discover, evaluate, and load on demand.

## Skills vs. Instructions: When to Use Each

The single most important decision is whether content should be **always loaded** (ambient instruction) or **loaded on demand** (skill). Getting this wrong wastes context budget or causes agents to miss critical rules.

### Always-On Instructions (Ambient)

**Mechanism**: Automatically loaded into every agent interaction. No tool calls needed.

**Platform locations**:

| Platform | Location | Format |
|----------|----------|--------|
| VS Code (Copilot) | `.github/instructions/*.instructions.md` | YAML frontmatter with `applyTo` glob |
| VS Code (Copilot) | `.github/copilot-instructions.md` or `AGENTS.md` | Plain markdown |
| Claude Code | `CLAUDE.md`, `.claude/CLAUDE.md` | Plain markdown with `@import` support |
| Claude Code | `.claude/rules/*.md` | YAML frontmatter with `paths` glob |

**Use for content that is**:
- A passive behavior that should always be active (coding style, commit conventions, tool preferences)
- Short enough that always-loading is negligible (~50 lines or fewer of actual rules)
- Needed on nearly every interaction of its type (e.g., every commit, every code review)
- Simple rule sets without complex workflows or extensive reference material

**Examples**: "Use imperative commit messages", "Prefer MCP tools over terminal", "Always attribute commits to Copilot"

### On-Demand Skills (Loaded When Relevant)

**Mechanism**: Agent reads only the `name` and `description` metadata at startup (~100 tokens). Full instructions load only when the task matches. Supports progressive disclosure with supporting files.

**Platform locations** (all follow the Agent Skills standard):

| Platform | Location |
|----------|----------|
| VS Code (Copilot) | `.github/skills/`, `.agents/skills/`, `.claude/skills/` |
| Claude Code | `.claude/skills/`, `~/.claude/skills/` |
| Cross-platform | Any of the above (standard is portable) |

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

## SKILL.md Format (Agent Skills Standard)

### Directory Structure

    skill-name/
    +-- SKILL.md           # Required entrypoint
    +-- references/        # Optional: detailed docs loaded on demand
    +-- scripts/           # Optional: executable scripts
    +-- assets/            # Optional: templates, schemas, data
    +-- examples/          # Optional: example inputs/outputs

### Required Frontmatter

    ---
    name: skill-name          # Lowercase, hyphens only, max 64 chars, must match directory name
    description: >-           # Max 1024 chars. Describe WHAT and WHEN.
      Detailed description including keywords that help agents identify relevant tasks.
    ---

### Optional Frontmatter Fields

| Field | Purpose |
|-------|---------|
| `license` | License name or reference to bundled LICENSE file |
| `compatibility` | Environment requirements (e.g., "Requires git, docker") |
| `metadata` | Arbitrary key-value pairs (author, version, etc.) |
| `allowed-tools` | Space-delimited list of pre-approved tools (experimental) |
| `argument-hint` | Hint for slash command arguments (e.g., `[filename] [options]`) |
| `user-invocable` | `false` to hide from `/` menu; background knowledge only |
| `disable-model-invocation` | `true` to prevent auto-loading; manual `/` invocation only |
| `context` | `fork` to run in a subagent (Claude Code) |

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

1. **Level 1 -- Discovery** (~100 tokens): `name` and `description` from frontmatter are always loaded for all skills. This is lightweight and always in context.
2. **Level 2 -- Instructions** (<5000 tokens recommended): The full `SKILL.md` body loads when the agent determines the skill is relevant or the user invokes it.
3. **Level 3 -- Resources** (as needed): Supporting files (scripts, references, assets) load only when explicitly referenced during execution.

This means you can install many skills without consuming context. Only what's relevant loads.

## Cross-Platform Compatibility Notes

**Skills are portable**. The Agent Skills standard (`SKILL.md` format) works across VS Code, Claude Code, GitHub Copilot CLI, and many other tools. Write skills once, use everywhere.

**Instructions are platform-specific**. Always-on instruction files differ by platform:
- VS Code uses `.github/instructions/*.instructions.md` with `applyTo` frontmatter
- Claude Code uses `.claude/rules/*.md` with `paths` frontmatter, or `CLAUDE.md` with `@import` syntax

**For maximum compatibility**, prefer skills for portable content and duplicate ambient instructions across platform formats only when needed.

## Best Practices

- **Be specific**: Target a clear, narrow task per skill. One topic per instruction file.
- **Use examples**: Concrete good/bad examples are more effective than abstract rules.
- **Size-appropriate**: Short passive rules -> instructions. Long reference material -> skills.
- **Cross-reference**: Ambient instructions should link to related skills for deeper guidance.
- **Keep SKILL.md focused**: Under 500 lines. Move detailed docs to `references/` subdirectory.
- **Descriptive names**: Both skill directory names and instruction file names should indicate their purpose.
- **Iterate**: Refine based on agent performance. If an instruction is too often ignored, it may need examples.
- **Evaluate regularly**: Use the [evaluation prompt](.github/prompts/evaluate-skills-instructions.prompt.md) to audit placement periodically.

## Reference Documentation

- [Agent Skills Open Standard](https://agentskills.io/) -- Portable specification
- [Agent Skills Specification](https://agentskills.io/specification) -- Detailed format reference
- [VS Code: Agent Skills](https://code.visualstudio.com/docs/copilot/customization/agent-skills) -- VS Code integration
- [VS Code: Custom Instructions](https://code.visualstudio.com/docs/copilot/customization/custom-instructions) -- Instruction file format
- [Claude Code: Skills](https://code.claude.com/docs/en/skills) -- Claude Code skill features
- [Claude Code: Memory](https://code.claude.com/docs/en/memory) -- CLAUDE.md and rules format
- [Example Skills Repository](https://github.com/anthropics/skills) -- Reference implementations
- [Awesome Copilot](https://github.com/github/awesome-copilot) -- Community examples
