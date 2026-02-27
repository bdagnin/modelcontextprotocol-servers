---
name: Agent Skills Support
description: Guidance for discovering and using Agent Skills in this workspace.
applyTo: "**/*"
---
# Agent Skills Support

This workspace uses the [Agent Skills](https://agentskills.io/) open standard. Skills are stored in `.agents/skills/` and are discovered automatically by compatible agents.

If your agent does not natively support Agent Skills progressive disclosure, follow this fallback strategy:

1. **Discovery**: Scan `.agents/skills/` for `SKILL.md` files. Read only the `name:` and `description:` frontmatter fields.
2. **Selective Loading**: Load the full `SKILL.md` body only when its description matches your current task.
3. **Efficiency**: Do not load multiple skill files at once unless all are clearly relevant.
