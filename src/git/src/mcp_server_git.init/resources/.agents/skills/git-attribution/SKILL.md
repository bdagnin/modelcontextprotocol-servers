---
name: git-attribution
description: Guidelines for attributing commits correctly for traceability when using git to commit changes.
---

# Attribution when committing changes to Git

When using git to commit changes, it is important to attribute the commits correctly for traceability.
When creating a commit, you should set the author information to reflect that the changes were made by an AI agent.

## Commit Attribution

When committing changes, attribute them to the AI assistant for traceability:

1. **MCP tool commits** (preferred): Use available author parameters if the tool supports them. Otherwise, include a `Co-authored-by:` trailer in the message body.
2. **`--author` flag**: Use `git commit --author="<assistant-name> <assistant-email>"` when the `Co-authored-by` approach is not suitable.
3. **Inline config**: Use git inline config to set the author information when not using the `commit` command, for example: `git -c user.name="<assistant-name>" -c user.email="<assistant-email>" commit -m "Your commit message"`.
4. **`Co-authored-by` trailer**: Add a `Co-authored-by:` line in the commit message body with your identity. Common examples:
    - `Co-authored-by: Claude <noreply@anthropic.com>`
    - `Co-authored-by: GitHub Copilot <noreply@github.com>`

    When possible, include your model designation and version for finer traceability (e.g., `Co-authored-by: Claude (claude-sonnet-4-20250514) <noreply@anthropic.com>`).

