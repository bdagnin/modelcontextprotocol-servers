---
name: MCP Git Tooling Guidelines
description: Instructions for using Git in Agent mode
---

# Copilot Instructions: Safe Git Tooling

When working in Agent mode, prefer MCP *tools* over terminal commands.

## Allowed Git MCP Tools

### Read-only operations (always safe):
- `git_status` - Check repository status
- `git_diff_unstaged` - View unstaged changes
- `git_diff_staged` - View staged changes
- `git_diff` - View general diffs
- `git_log` - View commit history
- `git_show` - Show specific commits

### Safe write operations:
- `git_add` - Stage files for commit
- `git_commit` - Create commits with proper messages

## Commit Guidelines

**IMPORTANT**: Always set your identity when committing.
Use `author_name="GitHub Copilot"` and `author_email="copilot@github.com"` if available, otherwise fallback to git inline config, eg: `git -c user.name="GitHub Copilot" -c user.email="copilot@github.com" commit -m "message"`

### Commit Message

Use simple, imperative subject lines in present tense:
- Start with an action verb: Add, Fix, Refactor, Document, Convert, Update, etc.
- Keep under 50 characters when possible
- No type prefixes or scope annotations
- No trailing period

Examples:
- `Add script to correlate blocking with sp_who2 logs`
- `Fix incorrect field time conversion for controller status event`
- `Document the event service structure`
- `Refactor time conversion for controller events to use UtcToControllerTime method`

The commit message body should be concise and explain the "why" behind changes.

## Restrictions

- **Avoid branch operations** unless explicitly requested by the user
- **Never force push** or perform destructive operations
- **Always ask for confirmation** before commits that affect multiple files
