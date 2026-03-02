---
name: git-commitmsg-imperative
description: Guidelines for crafting effective commit messages in imperative mood when using git to commit changes.
---

# Writing Imperative Commit Messages

Use **imperative mood** for commit messages:

- Start with an action verb: Add, Fix, Refactor, Document, Update, Convert, etc.
- Keep subject under 50 characters when possible.
- No type prefixes or scope annotations (e.g., not `feat(core):`).
- No trailing period.
- Body should be concise and explain the "why" behind changes.
- **Good**: `Add script to correlate blocking logs`, `Fix incorrect time conversion`
- **Bad**: `Added script` (passive), `fixing bug` (gerund), `feat(core): update logic` (prefix)
