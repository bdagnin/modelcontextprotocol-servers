---
name: Claude Skills Support
description: Manual support for Claude-style SKILL.md instruction files in VS Code.
applyTo: "**/*"
---
# Claude Skills Support
This workspace uses a "skills" pattern (originally designed for Claude Code) to define specialized agent capabilities.
To minimize context usage while maintaining high performance, follow this discovery and selective loading strategy:

1. **Discovery & Filtering**:
   - Use `list_dir` to see available skills in the root `skills/` directory.
   - Use a text-search tool (e.g., `grep_search`) to read only the `description:` and `name:` lines from the `SKILL.md` files (using a search pattern like `skills/**/SKILL.md`).
2. **Selective Loading**:
   - Evaluate the descriptions against your current task and user request.
   - Load the *full content* of a `SKILL.md` file using `read_file` ONLY if its description indicates it is directly applicable to your current goal.
3. **Application**: Apply the specific instructions, examples, and constraints from the loaded skill to your work.
4. **Efficiency**: Do not load multiple skill files at once unless they are all clearly relevant. This keeps the prompt focused and minimizes latency.
