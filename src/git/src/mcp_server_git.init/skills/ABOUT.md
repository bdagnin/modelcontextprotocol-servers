# About This Directory: Agentic Skills

This directory contains `SKILL.md` files that define specialized capabilities for Claude (and other agentic systems) to enhance performance on specific tasks.

## What is a Skill?

A skill is a self-contained folder containing a `SKILL.md` file. This file provides instructions, examples, and guidelines that the AI loads dynamically to ensure consistent, high-quality execution of repeated tasks.

Each skill consists of:
1. **YAML Frontmatter**: Defines metadata like `name` and `description`.
2. **Body**: Contains markdown instructions, examples, and guidelines.

## When to Create a New Skill

Create a new skill when you identify a task or workflow that:
- Is performed repeatedly.
- Requires specific formatting, style, or procedure.
- Benefits from specific examples to ensure correctness.
- Can be encapsulated with clear input/output expectations.

Examples include:
- Generating commit messages in a specific project style.
- Creating pull request descriptions.
- Writing documentation for a specific module.
- Handling specific error types or debugging workflows.

## How to Create a Skill

1. **Create a Folder**: Name the folder descriptively (e.g., `git.commitmsg.imperative`). The folder name acts as the skill ID in some contexts.
2. **Add `SKILL.md`**: Create a file named `SKILL.md` inside the folder.
3. **Define Metadata**:
   Add YAML frontmatter at the top of `SKILL.md`:
   ```yaml
   ---
   name: [Human-readable name]
   description: [Clear description of what the skill does]
   ---
   ```
4. **Write Instructions**:
   - Use clear, actionable language.
   - Provide concrete examples (both good and bad if helpful).
   - List guidelines or constraints.
   - Use sections like `## Instructions`, `## Examples`, `## Guidelines`.

## Directory Structure

```
skills/
  ├── [skill-name]/
  │     ├── SKILL.md
  │     └── [optional-resources]
  └── ...
```

## Best Practices

- **Be Specific**: Target a clear, narrow task.
- **Use Examples**: Examples are often more powerful than abstract instructions.
- **Iterate**: Refine the skill based on how the agent performs.
- **Keep it Self-Contained**: Ideally, a skill should not depend on external context not provided in the `SKILL.md` or the immediate conversation.
