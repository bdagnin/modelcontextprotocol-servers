---
description: Review a pull request in the context of its Notion task (auto-detect platform)
argument-hint: pr_url: The URL of the pull request to review
tools: [
  'git_checkout', 'git_diff', 'git_log', 'git_show', 'git_status', 
  'notion-fetch', 'notion-get-comments', 'notion-search',
  'repo_get_pull_request_by_id', 'repo_get_repo_by_name_or_id', 'repo_list_pull_request_thread_comments', 'repo_list_pull_request_threads', 'repo_list_pull_requests_by_commits', 'repo_list_pull_requests_by_repo_or_project', 'repo_search_commits',
  'asana_task_get', 'zendesk_ticket_get', 'docs_search', 'docs_find_by_name'
  ]
---

Examine the pull-request URL {{pr_url}} to determine what platform it's hosted on, then review the PR using the appropriate prompt for that platform.

Only use the tools listed in the child prompt file.

## General review instructions

Follow the instructions in #file:./pr-review.general.md to review the PR in the context of its Notion task.

## Platform URL formats

### GitHub

URL template: https://github.com/{owner}/{repo}/pull/{number}
Example: https://github.com/integratedcontroltechnology/MonoApiService/pull/655
- owner: integratedcontroltechnology
- repo: MonoApiService
- number: 655

Organisation whitelist:
- integratedcontroltechnology

No specific prompt file.

### AzureDevOps (new format)

URL template: https://dev.azure.com/{organization}/{project}/_git/{repo}/pullrequest/{number}
Example: https://dev.azure.com/incontrol-tfs/ProtegeGX/_git/PRT_GX/pullrequest/19987
- organization: incontrol-tfs
- project: ProtegeGX
- repo: PRT_GX
- number: 19987

Organisation whitelist:
- incontrol-tfs

Review using #file:./pr-review.ado.md

### AzureDevOps (old format)
URL template: https://{organization}.visualstudio.com/{project}/_git/{repo}/pullrequest/{number}
Example: https://incontrol-tfs.visualstudio.com/ProtegeGX/_git/PRT_GX/pullrequest/19987
- organization: incontrol-tfs
- project: ProtegeGX
- repo: PRT_GX
- number: 19987

Organisation whitelist:
- incontrol-tfs

Review using #file:./pr-review.ado.md
