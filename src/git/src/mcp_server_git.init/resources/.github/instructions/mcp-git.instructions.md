---
name: Git Guidelines
description: Ambient guidelines for git operations including commit attribution, message style, and MCP tool preference.
applyTo: "**/*"
---
# Git Guidelines

These rules apply to ALL git operations. Follow them automatically without needing to load additional files.

## Prefer MCP Tools

Always prefer MCP tools (e.g., `mcp_git_git_status`, `mcp_git_git_diff`, `mcp_git_git_commit`) over terminal commands for git operations. MCP tools can be auto-approved for autonomous workflow, while terminal commands require manual user approval, causing interruptions. Only fall back to terminal `git` if the required functionality is completely missing from available MCP tools.

## Commit Attribution

When committing changes, attribute them to GitHub Copilot for traceability:

- **Terminal commits**: Use `git commit --author="GitHub Copilot <copilot@github.com>" -m "message"` or `git -c user.name="GitHub Copilot" -c user.email="copilot@github.com" commit -m "message"`.
- **MCP tool commits**: Use available author parameters. If not available, add `Co-authored-by: GitHub Copilot <copilot@github.com>` in the commit message body.
- When possible, include your model designation in the author name, e.g., `--author="GitHub Copilot (gpt-4.0) <copilot@github.com>"`.

## Commit Message Style

Use **imperative mood** for commit messages:

- Start with an action verb: Add, Fix, Refactor, Document, Update, Convert, etc.
- Keep subject under 50 characters when possible.
- No type prefixes or scope annotations (e.g., not `feat(core):`).
- No trailing period.
- Body should be concise and explain the "why" behind changes.
- **Good**: `Add script to correlate blocking logs`, `Fix incorrect time conversion`
- **Bad**: `Added script` (passive), `fixing bug` (gerund), `feat(core): update logic` (prefix)

## Detailed Git MCP Workflows

For complex git operations (diffing branches, searching code, multi-step workflows), load the on-demand skill: [.agents/skills/mcp-server-git/SKILL.md](.agents/skills/mcp-server-git/SKILL.md)
