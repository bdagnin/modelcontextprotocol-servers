---
name: MCP Git tool usage patterns
description: Tooling usage patterns and limitations when using Git in Agent mode
---

# Git MCP Usage Instructions

These instructions are based on analysis of the Git MCP tools behavior in this workspace.

## Git Diff

The `git_diff` tool's `target` parameter has specific behaviors:

1.  **Supported Formats:**
    *   **Single SHA/Ref:** Passing a single commit SHA or ref (e.g., `34c6f6`) works and acts like `git diff <commit>`. It shows the changes introduced by that commit (effectively the same as `git show <commit>`).
    *   **Unsupported Formats:** The tool does **NOT** appear to support standard `git diff` range syntaxes such as:
        *   `SHA1..SHA2` (double dot)
        *   `SHA1...SHA2` (triple dot)
        *   `SHA1 SHA2` (space separated)
    *   **Error Message:** When an unsupported format is used, the tool returns generic errors like `Ref '...' did not resolve to an object`.

2.  **Usage Strategy:**
    *   To see changes in a specific commit: Use `git_diff` (or `git_show`) with the single commit SHA.
    *   To compare two commits: Since the tool doesn't support ranges, you cannot directly diff two arbitrary commits using `git_diff`. You may need to inspect individual commits or use `git_diff` with a single SHA to see what *that* commit changed relative to its parent. 
    *   **Note:** The behavior of `target` seems synonymous with providing a single "committish" argument to `git show` or `git diff` where it implies "diff this commit against its parent".

## Git Show

The `git_show` tool allows viewing commit details and file contents, but has specific path resolution rules:

1.  **Commit Details:**
    *   You can view full commit details (metadata + full diff) by passing just the SHA to the `revision` parameter.
    *   Example: `revision: "d66833fe4bae2280ea8f9eb8fb91c4b1409336f6"`

2.  **File Content at Revision:** 
    *   **NOT Supported:** The standard `git show SHA:path/to/file` syntax does **NOT** work. It returns errors like `"Blob or Tree named 'filename^0' not found"`.
    *   **Implication:** You cannot easily retrieve the full content of a specific file at a past revision using `git_show` with the `SHA:path` syntax.
    *   **Workaround:** To see what changed in a file, view the commit diff (using the SHA). If you need the full file content, you might have to checkout that commit (risky/disruptive) or rely on the diff context.

3.  **Diff Filtering:**
    *   `git_show` does not accept a `file_path` argument to filter the diff of a commit to a specific file. It returns the *entire* diff for that commit. You must parse the output to find the specific file you are interested in.

## General Best Practices

*   **Avoid Complex Refs:** Stick to simple SHAs or clear branch names. Avoid `..` or `...` ranges in MCP tool arguments unless explicitly documented as supported.
*   **Repo Path:** Always provide the full absolute path to the repository in `repo_path`.
*   **Checkout Safety:** Be careful with `git_checkout` if there are unstaged changes. Use `git_status` first.
*   **Large Diffs:** Since `git_show` returns the full diff, be prepared for large outputs. Use `grep` or specific `read_file` strategies if you only need small pieces, though `git_show` doesn't support reading partial diffs natively via the tool.

## Summary of Tool Capabilities based on Testing

| Task | Tool | Syntax/Parameter | Status |
| :--- | :--- | :--- | :--- |
| **Show Commit Diff** | `git_show` | `revision: "SHA"` | ✅ Works |
| **Show Commit Diff** | `git_diff` | `target: "SHA"` | ✅ Works (Equivalent to Show) |
| **Diff Range (..)** | `git_diff` | `target: "SHA1..SHA2"` | ❌ Fails |
| **Diff Range (...)** | `git_diff` | `target: "SHA1...SHA2"` | ❌ Fails |
| **Diff Range (space)**| `git_diff` | `target: "SHA1 SHA2"` | ❌ Fails |
| **File at Revision** | `git_show` | `revision: "SHA:path/file"`| ❌ Fails |
| **File at Revision** | `git_show` | `revision: "SHA:./file"` | ❌ Fails |
