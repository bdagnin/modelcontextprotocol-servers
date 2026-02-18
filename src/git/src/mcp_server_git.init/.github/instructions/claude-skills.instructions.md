---
name: Claude Skills Support
description: Manual support for Claude-style SKILL.md instruction files in VS Code.
applyTo: "**/*"
---
# Claude Skills Support
This workspace uses a "skills" pattern (originally designed for Claude Code) to define specialized agent capabilities. 
When working on tasks, you should actively look for and apply instructions from these files:

1. **Discovery**: Look in the root `skills/` directory. Each subfolder represents a skill.
2. **Loading**: Read the `SKILL.md` file within each folder.
3. **Application**: Apply the instructions, examples, and constraints found in `SKILL.md` if the task matches the skill's description (found in the YAML frontmatter).
4. **Context**: These skills are self-contained and provide high-quality guidelines for repetitive or specific tasks.
