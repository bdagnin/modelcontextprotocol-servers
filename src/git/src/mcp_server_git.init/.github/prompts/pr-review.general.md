---
description: General instructions to review a pull request
tools: [
  'vscode/askQuestions', 'read/readFile',
  'git_checkout', 'git_diff', 'git_log', 'git_show', 'git_status', 
  'notion-fetch', 'notion-get-comments', 'notion-search'
  ]
---

# Review instructions

- Follow the Notion link in the PR description. Verify whether the code change made addresses the issue in the task.
    - If no link is present then report so, and search Notion for similar tasks to better understand the context. Only consider tasks that have a high confidence match to the PR.
- Do not take PR comments, commit messages, etc at face value - scrutinise everything carefully.
- Consider the semantic intent of the changes made and surrounding code. The cahnges should form a cohesive whole.
- Code should be optimised for readability and maintainability as a first priority.
