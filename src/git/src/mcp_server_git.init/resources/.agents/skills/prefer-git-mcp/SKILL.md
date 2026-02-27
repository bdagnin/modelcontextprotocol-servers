---
name: prefer-git-mcp
description: Instructions to allow autonomy when interacting with git or issuing git commands in Agent mode, by preferring the use of MCP tools for git operations.
---

# Using the git MCP Tools

To allow autonomy when working in Agent mode, always prefer MCP *tools* over terminal commands for git operations.

## Background and Reasoning

When AI agents execute terminal commands, these actions typically require manual review and approval from the user. This causes interruptions, delays, and breaks the flow of autonomous background work.

Conversely, MCP tools offer safe, structured git operations that users can whitelist for auto-approval. By utilizing these tools, you can proceed autonomously without blocking on user input, significantly improving efficiency.

## Guidelines

1. **Prefer MCP Tools First**: Always check if an available git MCP tool can accomplish your task (e.g., `mcp_git_git_status`, `mcp_git_git_diff`, `mcp_git_git_commit`, etc.).
2. **Fallback to Terminal**: Only use the full-featured command-line `git` via terminal if the required functionality is completely missing from the available MCP tools.
3. **Chain Tools Autonomously**: Use the tools in sequence to complete complex git workflows without prompting the user for terminal command approvals.
