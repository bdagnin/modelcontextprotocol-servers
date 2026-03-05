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

<!-- #file: auto-injects content in VS Code; these short skills are kept in .agents/skills/ for cross-platform discoverability but injected here so they're effectively ambient in VS Code. -->
When committing changes, refer to #file:../../.agents/skills/git-attribution/SKILL.md for detailed guidelines on attributing commits to the AI assistant for traceability.

## Commit Message Style

When committing changes, refer to #file:../../.agents/skills/git-commitmsg-imperative/SKILL.md for detailed guidelines on crafting effective commit messages in imperative mood.

## Detailed Git MCP Workflows

<!-- This uses a markdown link (not #file:) intentionally — the MCP workflow skill is longer reference material meant to be loaded on-demand, not auto-injected into every interaction. -->
For complex git operations (diffing branches, searching code, multi-step workflows), load the on-demand skill: [.agents/skills/mcp-server-git/SKILL.md](../../.agents/skills/mcp-server-git/SKILL.md)
