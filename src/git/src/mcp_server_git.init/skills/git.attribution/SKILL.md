---
name: Attribution when committing changes to git
description: Guidelines for attributing commits correctly when using git for traceability.
---

# Attribution when committing changes to Git

When using git to commit changes, it is important to attribute the commits correctly for traceability.
When creating a commit, you should set the author information to reflect that the changes were made by GitHub Copilot.

If using commandline/terminal commands, you can set the author information inline with the commit command, for example: `git commit --author="GitHub Copilot <copilot@github.com>" -m "Your commit message"`.

Alternatively, when not using the `commit` command, use git inline config to set the author information, for example: `git -c user.name="GitHub Copilot" -c user.email="copilot@github.com" commit -m "Your commit message"`.

When possible, include your model designation and version in the author name for better traceability, e.g., `--author="GitHub Copilot (gpt-4.0) <copilot@github.com>"`, or `-c user.name="GitHub Copilot (gpt-4.0)"`.

If using MCP tools to commit, then use available parameters to set the author information. If such parameters are not available, do not fall back to commandline tools solely for this purpose, ensure that the commit message clearly indicates that the changes were made by GitHub Copilot for traceability, ; prefer using the co-author field in the commit message body, e.g., `Co-authored-by: GitHub Copilot <copilot@github.com>`.
