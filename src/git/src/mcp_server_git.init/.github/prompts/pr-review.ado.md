---
description: Review an AzureDevOps pull request in the context of its Notion task.
tools: [
  'git_checkout', 'git_diff', 'git_log', 'git_show', 'git_status', 
  'notion-fetch', 'notion-get-comments', 'notion-search',
  'repo_get_pull_request_by_id', 'repo_get_repo_by_name_or_id', 'repo_list_pull_request_thread_comments', 'repo_list_pull_request_threads', 'repo_list_pull_requests_by_commits', 'repo_list_pull_requests_by_repo_or_project', 'repo_search_commits'
  ]
argument-hint: pr_url: The URL of the AzureDevOps pull request to review.
---

# Reviewing an Azure DevOps PR

Do not use general Azure tools - 'Azure DevOps' is a separate product.
Use AzureDevOps tools to review the PR.
The git commits are available in the local repo.

#file:./pr-review.general.md
