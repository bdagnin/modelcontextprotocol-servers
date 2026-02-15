---
name: Using the git MCP Tools
description: Instructions and best practices for using the git MCP tools effectively in this workspace.
---

# Using the git MCP Tools

When working in Agent mode, prefer MCP *tools* over terminal commands for git operations.

## Common git workflows with MCP tools

### Reviewing local changes
- Use `git_status` to check the current state of the repository.
- Use `git_diff_unstaged` to view changes in unstaged files.
- Use `git_diff_staged` to view changes that are staged for commit.

### Reviewing remote changes
- Use `git_fetch` to update remote references (if available).
- Use `git_log` to compare local and remote branches.
- Use `git_diff` to view differences between branches or commits.
  - Use the `base` and `target` parameters to specify the commits or branches to compare.
    - `base` can be a commit SHA, branch name, or ref, and is the starting point of the diff.
    - `target` can be a commit SHA, branch name, or ref, and is the ending point of the diff.
    - do not use unsupported range syntaxes like `SHA1..SHA2` or `SHA1...SHA2` as they may not be supported by the tool.

### Committing changes
- Use `git_add` to stage specific files or changes for commit.
- Use `git_commit` to create the commit.
  - When committing, include `author_name` and `author_email` if required by the environment, or rely on git configuration.

### Branch Management
- Use `git_branch` to list or create branches.
- Use `git_checkout` to switch branches.

Do not perform branching operations unless explicitly requested by the user. If you think that branching is necessary, ask the user for confirmation first.
