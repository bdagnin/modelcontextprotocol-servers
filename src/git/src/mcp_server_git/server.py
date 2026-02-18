import logging
from pathlib import Path
from typing import Sequence, Optional
from mcp.server import Server
from mcp.server.session import ServerSession
from mcp.server.stdio import stdio_server
from mcp.types import (
    ClientCapabilities,
    TextContent,
    Tool,
    ListRootsResult,
    RootsCapability,
)
from enum import Enum
import git
from git.exc import BadName
from pydantic import BaseModel, Field

# Default number of context lines to show in diff output
DEFAULT_CONTEXT_LINES = 3

class GitStatus(BaseModel):
    repo_path: str
    paths: Optional[list[str]] = None

class GitDiffUnstaged(BaseModel):
    repo_path: str
    context_lines: int = DEFAULT_CONTEXT_LINES
    ignore_whitespace: bool = False
    paths: Optional[list[str]] = None

class GitDiffStaged(BaseModel):
    repo_path: str
    context_lines: int = DEFAULT_CONTEXT_LINES
    ignore_whitespace: bool = False
    paths: Optional[list[str]] = None

class GitDiff(BaseModel):
    repo_path: str
    target: str
    base: Optional[str] = None
    merge_base: bool = Field(
        False,
        description="When True and 'base' is provided, diff target against the merge base of base and target (equivalent to 'git diff base...target'). Useful for pull request review to see only the changes introduced by the PR branch, ignoring commits made to the target branch after the PR branch diverged."
    )
    context_lines: int = DEFAULT_CONTEXT_LINES
    ignore_whitespace: bool = False
    paths: Optional[list[str]] = None

class GitCommit(BaseModel):
    repo_path: str
    message: str
    author_name: Optional[str] = None
    author_email: Optional[str] = None

class GitAdd(BaseModel):
    repo_path: str
    files: list[str]

class GitReset(BaseModel):
    repo_path: str
    paths: Optional[list[str]] = None

class GitLog(BaseModel):
    repo_path: str
    max_count: int = 10
    revision_range: Optional[str] = None
    paths: Optional[list[str]] = None
    start_timestamp: Optional[str] = Field(
        None,
        description="Start timestamp for filtering commits. Accepts: ISO 8601 format (e.g., '2024-01-15T14:30:25'), relative dates (e.g., '2 weeks ago', 'yesterday'), or absolute dates (e.g., '2024-01-15', 'Jan 15 2024')"
    )
    end_timestamp: Optional[str] = Field(
        None,
        description="End timestamp for filtering commits. Accepts: ISO 8601 format (e.g., '2024-01-15T14:30:25'), relative dates (e.g., '2 weeks ago', 'yesterday'), or absolute dates (e.g., '2024-01-15', 'Jan 15 2024')"
    )

class GitCreateBranch(BaseModel):
    repo_path: str
    branch_name: str
    base_branch: str | None = None

class GitCheckout(BaseModel):
    repo_path: str
    branch_name: str

class GitShow(BaseModel):
    repo_path: str
    revision: str



class GitBranch(BaseModel):
    repo_path: str = Field(
        ...,
        description="The path to the Git repository.",
    )
    branch_type: str = Field(
        ...,
        description="Whether to list local branches ('local'), remote branches ('remote') or all branches('all').",
    )
    contains: Optional[str] = Field(
        None,
        description="The commit sha that branch should contain. Do not pass anything to this param if no commit sha is specified",
    )
    not_contains: Optional[str] = Field(
        None,
        description="The commit sha that branch should NOT contain. Do not pass anything to this param if no commit sha is specified",
    )


class GitGrep(BaseModel):
    repo_path: str
    pattern: str
    revision: Optional[str] = None
    paths: Optional[list[str]] = None
    ignore_case: bool = False
    line_numbers: bool = True


class GitTools(str, Enum):
    STATUS = "git_status"
    DIFF_UNSTAGED = "git_diff_unstaged"
    DIFF_STAGED = "git_diff_staged"
    DIFF = "git_diff"
    COMMIT = "git_commit"
    ADD = "git_add"
    RESET = "git_reset"
    LOG = "git_log"
    CREATE_BRANCH = "git_create_branch"
    CHECKOUT = "git_checkout"
    SHOW = "git_show"
    GREP = "git_grep"

    BRANCH = "git_branch"

def git_status(repo: git.Repo, paths: list[str] | None = None) -> str:
    args = []
    if paths:
        args.extend(["--", *paths])
    return repo.git.status(*args)

def git_diff_unstaged(repo: git.Repo, context_lines: int = DEFAULT_CONTEXT_LINES, ignore_whitespace: bool = False, paths: list[str] | None = None) -> str:
    args = [f"--unified={context_lines}"]
    if ignore_whitespace:
        args.append("-w")
    if paths:
        args.extend(["--", *paths])
    return repo.git.diff(*args)

def git_diff_staged(repo: git.Repo, context_lines: int = DEFAULT_CONTEXT_LINES, ignore_whitespace: bool = False, paths: list[str] | None = None) -> str:
    args = [f"--unified={context_lines}", "--cached"]
    if ignore_whitespace:
        args.append("-w")
    if paths:
        args.extend(["--", *paths])
    return repo.git.diff(*args)

def git_diff(repo: git.Repo, target: str, base: str | None = None, merge_base: bool = False, context_lines: int = DEFAULT_CONTEXT_LINES, ignore_whitespace: bool = False, paths: list[str] | None = None) -> str:
    # Defense in depth: reject targets starting with '-' to prevent flag injection,
    # even if a malicious ref with that name exists (e.g. via filesystem manipulation)
    if target.startswith("-"):
        raise BadName(f"Invalid target: '{target}' - cannot start with '-'")
    if base and base.startswith("-"):
        raise BadName(f"Invalid base: '{base}' - cannot start with '-'")
    
    repo.rev_parse(target)  # Validates target is a real git ref, throws BadName if not
    if base:
        repo.rev_parse(base)

    args = [f"--unified={context_lines}"]
    if ignore_whitespace:
        args.append("-w")
    
    if base:
        if merge_base:
            # Three-dot notation: diffs target against the merge base of base and target.
            # This shows only changes introduced by target's branch, ignoring commits
            # added to base after the branches diverged (ideal for PR review).
            args.append(f"{base}...{target}")
        else:
            args.extend([base, target])
    else:
        args.append(target)
        
    if paths:
        args.extend(["--", *paths])
        
    return repo.git.diff(*args)

def git_commit(repo: git.Repo, message: str, author_name: str | None = None, author_email: str | None = None) -> str:
    author = None
    if author_name and author_email:
        from git import Actor
        author = Actor(author_name, author_email)

    commit = repo.index.commit(message, author=author)
    return f"Changes committed successfully with hash {commit.hexsha}"

def git_add(repo: git.Repo, files: list[str]) -> str:
    if files == ["."]:
        repo.git.add(".")
    else:
        # Use '--' to prevent files starting with '-' from being interpreted as options
        repo.git.add("--", *files)
    return "Files staged successfully"

def git_reset(repo: git.Repo, paths: list[str] | None = None) -> str:
    if paths:
        repo.index.reset(paths=paths)
        return f"Reset {len(paths)} files"
    repo.index.reset()
    return "All staged changes reset"

def git_log(repo: git.Repo, max_count: int = 10, revision_range: str | None = None, paths: list[str] | None = None, start_timestamp: str | None = None, end_timestamp: str | None = None) -> list[str]:
    kwargs = {'max_count': max_count}
    if start_timestamp:
        kwargs['since'] = start_timestamp
    if end_timestamp:
        kwargs['until'] = end_timestamp
    if revision_range:
        kwargs['rev'] = revision_range
    if paths:
        kwargs['paths'] = paths
        
    commits = list(repo.iter_commits(**kwargs))
    log = []
    for commit in commits:
        log.append(
            f"Commit: {commit.hexsha!r}\n"
            f"Author: {commit.author!r}\n"
            f"Date: {commit.authored_datetime}\n"
            f"Message: {commit.message!r}\n"
        )
    return log

def git_create_branch(repo: git.Repo, branch_name: str, base_branch: str | None = None) -> str:
    if base_branch:
        base = repo.references[base_branch]
    else:
        base = repo.active_branch

    repo.create_head(branch_name, base)
    return f"Created branch '{branch_name}' from '{base.name}'"

def git_checkout(repo: git.Repo, branch_name: str) -> str:
    # Defense in depth: reject branch names starting with '-' to prevent flag injection,
    # even if a malicious ref with that name exists (e.g. via filesystem manipulation)
    if branch_name.startswith("-"):
        raise BadName(f"Invalid branch name: '{branch_name}' - cannot start with '-'")
    repo.rev_parse(branch_name)  # Validates branch_name is a real git ref, throws BadName if not
    repo.git.checkout(branch_name)
    return f"Switched to branch '{branch_name}'"



def git_show(repo: git.Repo, revision: str) -> str:
    commit = repo.commit(revision)
    output = [
        f"Commit: {commit.hexsha!r}\n"
        f"Author: {commit.author!r}\n"
        f"Date: {commit.authored_datetime!r}\n"
        f"Message: {commit.message!r}\n"
    ]
    if commit.parents:
        parent = commit.parents[0]
        diff = parent.diff(commit, create_patch=True)
    else:
        diff = commit.diff(git.NULL_TREE, create_patch=True)
    for d in diff:
        output.append(f"\n--- {d.a_path}\n+++ {d.b_path}\n")
        if d.diff is None:
            continue
        if isinstance(d.diff, bytes):
            output.append(d.diff.decode('utf-8'))
        else:
            output.append(d.diff)
    return "".join(output)

def git_grep(repo: git.Repo, pattern: str, revision: str | None = None, paths: list[str] | None = None, ignore_case: bool = False, line_numbers: bool = True) -> str:
    args = []
    if ignore_case:
        args.append("-i")
    if line_numbers:
        args.append("-n")
    
    # We use -e to handle patterns starting with - safely
    args.append("-e")
    args.append(pattern)
    
    if revision:
        args.append(revision)
    
    args.append("--")
    
    if paths:
        args.extend(paths)
        
    return repo.git.grep(*args)

def validate_repo_path(repo_path: Path, allowed_repository: Path | None) -> None:
    """Validate that repo_path is within the allowed repository path."""
    if allowed_repository is None:
        return  # No restriction configured

    # Resolve both paths to handle symlinks and relative paths
    try:
        resolved_repo = repo_path.resolve()
        resolved_allowed = allowed_repository.resolve()
    except (OSError, RuntimeError):
        raise ValueError(f"Invalid path: {repo_path}")

    # Check if repo_path is the same as or a subdirectory of allowed_repository
    try:
        resolved_repo.relative_to(resolved_allowed)
    except ValueError:
        raise ValueError(
            f"Repository path '{repo_path}' is outside the allowed repository '{allowed_repository}'"
        )


def git_branch(repo: git.Repo, branch_type: str, contains: str | None = None, not_contains: str | None = None) -> str:
    match contains:
        case None:
            contains_sha = (None,)
        case _:
            contains_sha = ("--contains", contains)

    match not_contains:
        case None:
            not_contains_sha = (None,)
        case _:
            not_contains_sha = ("--no-contains", not_contains)

    match branch_type:
        case 'local':
            b_type = None
        case 'remote':
            b_type = "-r"
        case 'all':
            b_type = "-a"
        case _:
            return f"Invalid branch type: {branch_type}"

    # None value will be auto deleted by GitPython
    branch_info = repo.git.branch(b_type, *contains_sha, *not_contains_sha)

    return branch_info


async def serve(repository: Path | None) -> None:
    logger = logging.getLogger(__name__)

    if repository is not None:
        try:
            git.Repo(repository)
            logger.info(f"Using repository at {repository}")
        except git.InvalidGitRepositoryError:
            logger.error(f"{repository} is not a valid Git repository")
            return

    server = Server("mcp-git")

    @server.list_tools()
    async def list_tools() -> list[Tool]:
        return [
            Tool(
                name=GitTools.STATUS,
                description="Shows the working tree status",
                inputSchema=GitStatus.model_json_schema(),
            ),
            Tool(
                name=GitTools.DIFF_UNSTAGED,
                description="Shows changes in the working directory that are not yet staged",
                inputSchema=GitDiffUnstaged.model_json_schema(),
            ),
            Tool(
                name=GitTools.DIFF_STAGED,
                description="Shows changes that are staged for commit",
                inputSchema=GitDiffStaged.model_json_schema(),
            ),
            Tool(
                name=GitTools.DIFF,
                description="Shows differences between branches or commits",
                inputSchema=GitDiff.model_json_schema(),
            ),
            Tool(
                name=GitTools.COMMIT,
                description="Records changes to the repository",
                inputSchema=GitCommit.model_json_schema(),
            ),
            Tool(
                name=GitTools.ADD,
                description="Adds file contents to the staging area",
                inputSchema=GitAdd.model_json_schema(),
            ),
            Tool(
                name=GitTools.RESET,
                description="Unstages all staged changes",
                inputSchema=GitReset.model_json_schema(),
            ),
            Tool(
                name=GitTools.LOG,
                description="Shows the commit logs",
                inputSchema=GitLog.model_json_schema(),
            ),
            Tool(
                name=GitTools.CREATE_BRANCH,
                description="Creates a new branch from an optional base branch",
                inputSchema=GitCreateBranch.model_json_schema(),
            ),
            Tool(
                name=GitTools.CHECKOUT,
                description="Switches branches",
                inputSchema=GitCheckout.model_json_schema(),
            ),
            Tool(
                name=GitTools.SHOW,
                description="Shows the contents of a commit",
                inputSchema=GitShow.model_json_schema(),
            ),
            Tool(
                name=GitTools.GREP,
                description="Search for a pattern in the repository",
                inputSchema=GitGrep.model_json_schema(),
            ),

            Tool(
                name=GitTools.BRANCH,
                description="List Git branches",
                inputSchema=GitBranch.model_json_schema(),

            )
        ]

    async def list_repos() -> Sequence[str]:
        async def by_roots() -> Sequence[str]:
            if not isinstance(server.request_context.session, ServerSession):
                raise TypeError("server.request_context.session must be a ServerSession")

            if not server.request_context.session.check_client_capability(
                ClientCapabilities(roots=RootsCapability())
            ):
                return []

            roots_result: ListRootsResult = await server.request_context.session.list_roots()
            logger.debug(f"Roots result: {roots_result}")
            repo_paths = []
            for root in roots_result.roots:
                path = root.uri.path
                try:
                    git.Repo(path)
                    repo_paths.append(str(path))
                except git.InvalidGitRepositoryError:
                    pass
            return repo_paths

        def by_commandline() -> Sequence[str]:
            return [str(repository)] if repository is not None else []

        cmd_repos = by_commandline()
        root_repos = await by_roots()
        return [*root_repos, *cmd_repos]

    @server.call_tool()
    async def call_tool(name: str, arguments: dict) -> list[TextContent]:
        repo_path = Path(arguments["repo_path"])

        # Validate repo_path is within allowed repository
        validate_repo_path(repo_path, repository)

        # For all commands, we need an existing repo
        repo = git.Repo(repo_path)

        match name:
            case GitTools.STATUS:
                status = git_status(repo, arguments.get("paths"))
                return [TextContent(
                    type="text",
                    text=f"Repository status:\n{status}"
                )]

            case GitTools.DIFF_UNSTAGED:
                diff = git_diff_unstaged(
                    repo, 
                    arguments.get("context_lines", DEFAULT_CONTEXT_LINES),
                    arguments.get("ignore_whitespace", False),
                    arguments.get("paths")
                )
                return [TextContent(
                    type="text",
                    text=f"Unstaged changes:\n{diff}"
                )]

            case GitTools.DIFF_STAGED:
                diff = git_diff_staged(
                    repo, 
                    arguments.get("context_lines", DEFAULT_CONTEXT_LINES),
                    arguments.get("ignore_whitespace", False),
                    arguments.get("paths")
                )
                return [TextContent(
                    type="text",
                    text=f"Staged changes:\n{diff}"
                )]

            case GitTools.DIFF:
                diff = git_diff(
                    repo, 
                    arguments["target"], 
                    arguments.get("base"),
                    arguments.get("merge_base", False),
                    arguments.get("context_lines", DEFAULT_CONTEXT_LINES),
                    arguments.get("ignore_whitespace", False),
                    arguments.get("paths")
                )
                return [TextContent(
                    type="text",
                    text=f"Diff with {arguments['target']}:\n{diff}"
                )]

            case GitTools.COMMIT:
                result = git_commit(
                    repo, 
                    arguments["message"],
                    arguments.get("author_name"),
                    arguments.get("author_email")
                )
                return [TextContent(
                    type="text",
                    text=result
                )]

            case GitTools.ADD:
                result = git_add(repo, arguments["files"])
                return [TextContent(
                    type="text",
                    text=result
                )]

            case GitTools.RESET:
                result = git_reset(repo, arguments.get("paths"))
                return [TextContent(
                    type="text",
                    text=result
                )]

            case GitTools.LOG:
                log = git_log(
                    repo,
                    arguments.get("max_count", 10),
                    arguments.get("revision_range"),
                    arguments.get("paths"),
                    arguments.get("start_timestamp"),
                    arguments.get("end_timestamp")
                )
                return [TextContent(
                    type="text",
                    text="Commit history:\n" + "\n".join(log)
                )]

            case GitTools.CREATE_BRANCH:
                result = git_create_branch(
                    repo,
                    arguments["branch_name"],
                    arguments.get("base_branch")
                )
                return [TextContent(
                    type="text",
                    text=result
                )]

            case GitTools.CHECKOUT:
                result = git_checkout(repo, arguments["branch_name"])
                return [TextContent(
                    type="text",
                    text=result
                )]

            case GitTools.SHOW:
                result = git_show(repo, arguments["revision"])
                return [TextContent(
                    type="text",
                    text=result
                )]

            case GitTools.GREP:
                result = git_grep(
                    repo,
                    arguments["pattern"],
                    arguments.get("revision"),
                    arguments.get("paths"),
                    arguments.get("ignore_case", False),
                    arguments.get("line_numbers", True),
                )
                return [TextContent(
                    type="text",
                    text=result
                )]

            case GitTools.BRANCH:
                result = git_branch(
                    repo,
                    arguments.get("branch_type", 'local'),
                    arguments.get("contains", None),
                    arguments.get("not_contains", None),
                )
                return [TextContent(
                    type="text",
                    text=result
                )]

            case _:
                raise ValueError(f"Unknown tool: {name}")

    options = server.create_initialization_options()
    async with stdio_server() as (read_stream, write_stream):
        await server.run(read_stream, write_stream, options, raise_exceptions=True)
