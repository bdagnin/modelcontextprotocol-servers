---
name: git.commitmsg.imperative
description: Guidelines for crafting effective commit messages in imperative mood when using git to commit changes.
---

# Writing Imperative Commit Messages

Use simple, imperative subject lines in present tense when crafting commit messages.

## Guidelines
- Start with an action verb: Add, Fix, Refactor, Document, Convert, Update, etc.
- Keep under 50 characters when possible.
- No type prefixes or scope annotations.
- No trailing period.
- The commit message body should be concise and explain the "why" behind changes.

## Examples

### Good Subject Lines
- `Add script to correlate blocking with sp_who2 logs`
- `Fix incorrect field time conversion for controller status event`
- `Document the event service structure`
- `Refactor time conversion for controller events to use UtcToControllerTime method`

### Bad Subject Lines
- `Added script` (Passive)
- `fixing bug` (Gerund/Progressive)
- `feat(core): update logic` (Prefixes not allowed)

