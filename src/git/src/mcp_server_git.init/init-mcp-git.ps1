<#
.SYNOPSIS
    Automated MCP Git Server Setup Script
    
.DESCRIPTION
    Downloads and configures a portable Python environment with the mcp-server-git package
    and creates a workspace-specific MCP configuration.
    
.PARAMETER InstallDir
    Base directory for MCP installations (default: ~\apps\copilot-mcp)
    
.PARAMETER Force
    Force reinstall even if already exists
    
.EXAMPLE
    .\init-mcp-git.ps1
    
.EXAMPLE
    .\init-mcp-git.ps1 -InstallDir "C:\tools\mcp" -Force
#>

[CmdletBinding()]
param(
    [Parameter()]
    [string]$InstallDir = "$env:USERPROFILE\apps\copilot-mcp",
    
    [Parameter()]
    [string]$GitPath,
    
    [Parameter()]
    [switch]$Force
)

$ErrorActionPreference = "Stop"

# Configuration
$PythonVersion = $null  # Will be resolved dynamically
$GitServerDir = Join-Path $InstallDir "mcp-server-git"
$PythonDir = Join-Path $GitServerDir "python"
$PythonExe = Join-Path $PythonDir "python.exe"
$PipExe = Join-Path $PythonDir "Scripts\pip.exe"
$GitServerExe = Join-Path $PythonDir "Scripts\mcp-server-git.exe"

# Helper Functions
function Write-Step {
    param([string]$Message)
    Write-Host "`n===> $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "  ✓ $Message" -ForegroundColor Green
}

function Write-Info {
    param([string]$Message)
    Write-Host "  → $Message" -ForegroundColor Gray
}

function Test-GitInstalled {
    param([string]$gitExePath)
    try {
        $null = & $gitExePath --version
        return $true
    } catch {
        return $false
    }
}

function Get-GitPath {
    param([string]$CustomPath)
    
    # Check custom path first if provided
    if ($CustomPath) {
        if (Test-Path $CustomPath) {
            return $CustomPath
        } else {
            Write-Host "  ✗ Custom Git path not found: $CustomPath" -ForegroundColor Red
            exit 1
        }
    }
    
    # Try common installation location
    if (Test-Path "C:\Program Files\Git\bin\git.exe") {
        return "C:\Program Files\Git\bin\git.exe"
    }
    
    # Try PATH
    $gitCmd = Get-Command git -ErrorAction SilentlyContinue
    if ($gitCmd) {
        return $gitCmd.Source
    }
    
    return $null
}

function Get-LatestPythonVersion {
    Write-Info "Resolving latest Python 3.x version..."
    try {
        # Fetch the Python downloads page and parse for latest stable version
        $downloadPage = Invoke-WebRequest -Uri "https://www.python.org/downloads/windows/" -UseBasicParsing -TimeoutSec 10
        
        # Look for the latest release version in the page content
        if ($downloadPage.Content -match 'Latest Python 3 Release - Python (3\.\d+\.\d+)') {
            $latestVersion = $matches[1]
            Write-Info "Found latest version: $latestVersion"
            return $latestVersion
        }
        
        # Fallback: Try to parse from download links
        if ($downloadPage.Content -match 'python-(3\.\d+\.\d+)-amd64\.exe') {
            $latestVersion = $matches[1]
            Write-Info "Found latest version from links: $latestVersion"
            return $latestVersion
        }
    } catch {
        Write-Info "Could not resolve latest version dynamically: $_"
    }
    
    # Fallback to known stable version
    Write-Info "Using fallback version"
    return "3.12.8"
}

# Main Installation
Write-Host @"

╔═══════════════════════════════════════════════════════╗
║    MCP Git Server - Automated Setup Script            ║
║    Workspace-scoped Git MCP for GitHub Copilot        ║
╚═══════════════════════════════════════════════════════╝

"@ -ForegroundColor Cyan

# Check if already installed
if ((Test-Path $GitServerExe) -and -not $Force) {
    Write-Host "MCP Git Server already installed at: $GitServerExe" -ForegroundColor Yellow
    Write-Host "Use -Force to reinstall" -ForegroundColor Yellow
    $response = Read-Host "`nContinue with workspace configuration only? (Y/n)"
    if ($response -and $response -ne 'Y' -and $response -ne 'y') {
        Write-Host "Aborted." -ForegroundColor Red
        exit 0
    }
    $SkipInstall = $true
} else {
    $SkipInstall = $false
}

if (-not $SkipInstall) {
    # Create installation directory
    Write-Step "Creating installation directory"
    if (Test-Path $GitServerDir) {
        if ($Force) {
            Remove-Item $GitServerDir -Recurse -Force
        }
    }
    New-Item -ItemType Directory -Force -Path $GitServerDir | Out-Null
    Write-Success "Directory created: $GitServerDir"

    # Resolve latest Python version
    if (-not $PythonVersion) {
        $PythonVersion = Get-LatestPythonVersion
    }
    $PythonUrl = "https://www.python.org/ftp/python/$PythonVersion/python-$PythonVersion-amd64.zip"
    
    # Download Python
    Write-Step "Downloading Python $PythonVersion (portable)"
    $pythonZip = Join-Path $GitServerDir "python.zip"
    Write-Info "URL: $PythonUrl"
    try {
        Invoke-WebRequest -Uri $PythonUrl -OutFile $pythonZip -UseBasicParsing
        Write-Success "Python downloaded"
    } catch {
        Write-Host "  ✗ Failed to download Python: $_" -ForegroundColor Red
        exit 1
    }

    # Extract Python
    Write-Step "Extracting Python"
    try {
        Expand-Archive -Path $pythonZip -DestinationPath $PythonDir -Force
        Remove-Item $pythonZip
        Write-Success "Python extracted to: $PythonDir"
    } catch {
        Write-Host "  ✗ Failed to extract Python: $_" -ForegroundColor Red
        exit 1
    }

    # Verify pip availability and bootstrap if needed
    Write-Step "Verifying pip availability"
    $pipAvailable = $false
    try {
        & $PythonExe -m pip --version 2>&1 | Out-Null
        $pipAvailable = $true
        Write-Success "pip is available"
    } catch {
        Write-Info "pip not found, will bootstrap it"
    }
    
    if (-not $pipAvailable) {
        Write-Step "Bootstrapping pip"
        $getPipUrl = "https://bootstrap.pypa.io/get-pip.py"
        $getPipPath = Join-Path $GitServerDir "get-pip.py"
        try {
            Invoke-WebRequest -Uri $getPipUrl -OutFile $getPipPath -UseBasicParsing
            & $PythonExe $getPipPath --no-warn-script-location
            Remove-Item $getPipPath
            Write-Success "pip installed successfully"
        } catch {
            Write-Host "  ✗ Failed to bootstrap pip: $_" -ForegroundColor Red
            exit 1
        }
    }

    # Install mcp-server-git
    Write-Step "Installing mcp-server-git package"
    try {
        & $PythonExe -m pip install mcp-server-git --no-warn-script-location
        Write-Success "mcp-server-git installed"
        
        if (-not (Test-Path $GitServerExe)) {
            Write-Host "  ✗ mcp-server-git.exe not found after installation" -ForegroundColor Red
            exit 1
        }
    } catch {
        Write-Host "  ✗ Failed to install mcp-server-git: $_" -ForegroundColor Red
        exit 1
    }

    Write-Success "MCP Git Server installation complete!"
}

# Check for Git installation
Write-Step "Checking for Git installation"
$gitPath = Get-GitPath -CustomPath $GitPath
if (-not $gitPath) {
    Write-Host "  ✗ Could not locate Git executable" -ForegroundColor Red
    exit 1
}
if (-not (Test-GitInstalled -gitExePath $gitPath)) {
    Write-Host "  ✗ Git is not installed. Please install Git for Windows first." -ForegroundColor Red
    Write-Host "    Download from: https://git-scm.com/download/win" -ForegroundColor Yellow
    exit 1
}
Write-Success "Git found: $gitPath"

# Create workspace MCP configuration
Write-Step "Creating workspace MCP configuration"

$workspaceFolder = Get-Location
$vscodeDir = Join-Path $workspaceFolder ".vscode"
$mcpJsonPath = Join-Path $vscodeDir "mcp.json"

# Create .vscode directory if it doesn't exist
if (-not (Test-Path $vscodeDir)) {
    New-Item -ItemType Directory -Path $vscodeDir | Out-Null
    Write-Info "Created .vscode directory"
}

# Create MCP configuration
$mcpConfig = @{
    servers = @{
        git = @{
            command = $GitServerExe
            env = @{
                MCP_GIT_DEFAULT_REPO = '${workspaceFolder}'
                GIT_PYTHON_GIT_EXECUTABLE = $gitPath
            }
        }
    }
} | ConvertTo-Json -Depth 10

# Write configuration
try {
    $mcpConfig | Out-File -FilePath $mcpJsonPath -Encoding utf8 -Force
    Write-Success "Configuration created: $mcpJsonPath"
} catch {
    Write-Host "  ✗ Failed to create MCP configuration: $_" -ForegroundColor Red
    exit 1
}

# Add to .gitignore if not already present
Write-Step "Updating .gitignore"
$gitignorePath = Join-Path $workspaceFolder ".gitignore"
$gitignoreEntry = ".vscode/mcp.json"

if (Test-Path $gitignorePath) {
    $gitignoreContent = Get-Content $gitignorePath -Raw
    if ($gitignoreContent -notmatch [regex]::Escape($gitignoreEntry)) {
        Add-Content -Path $gitignorePath -Value "`n# MCP configuration (machine-specific)`n$gitignoreEntry"
        Write-Success "Added mcp.json to .gitignore"
    } else {
        Write-Info "mcp.json already in .gitignore"
    }
} else {
    "# MCP configuration (machine-specific)`n$gitignoreEntry" | Out-File -FilePath $gitignorePath -Encoding utf8
    Write-Success "Created .gitignore with mcp.json"
}

# Create copilot instructions for safe Git usage
# Copilot recognizes "*.instructions.md" files automatically.
Write-Step "Creating Copilot instructions for safe Git usage"
$githubDir = Join-Path $workspaceFolder ".github"
$gitInstructionsPath = Join-Path $githubDir "git.instructions.md"

# Create .github directory if needed
if (-not (Test-Path $githubDir)) {
    New-Item -ItemType Directory -Path $githubDir | Out-Null
    Write-Info "Created .github directory"
}

$gitInstructions = @"
---
name: MCP Git Tooling Guidelines
description: Instructions for using Git in Agent mode
---

# Copilot Instructions: Safe Git Tooling

When working in Agent mode, prefer MCP *tools* over terminal commands.

## Allowed Git MCP Tools

### Read-only operations (always safe):
- ``git_status`` - Check repository status
- ``git_diff_unstaged`` - View unstaged changes
- ``git_diff_staged`` - View staged changes
- ``git_diff`` - View general diffs
- ``git_log`` - View commit history
- ``git_show`` - Show specific commits

### Safe write operations:
- ``git_add`` - Stage files for commit
- ``git_commit`` - Create commits with proper messages

## Commit Guidelines

**IMPORTANT**: Always set your identity when committing.
Use ``author_name="GitHub Copilot"`` and ``author_email="copilot@github.com"`` if available, otherwise fallback to git inline config, eg: ``git -c user.name="GitHub Copilot" -c user.email="copilot@github.com" commit -m "message"``

### Commit Message

Use simple, imperative subject lines in present tense:
- Start with an action verb: Add, Fix, Refactor, Document, Convert, Update, etc.
- Keep under 50 characters when possible
- No type prefixes or scope annotations
- No trailing period

Examples:
- ``Add script to correlate blocking with sp_who2 logs``
- ``Fix incorrect field time conversion for controller status event``
- ``Document the event service structure``
- ``Refactor time conversion for controller events to use UtcToControllerTime method``

The commit message body should be concise and explain the "why" behind changes.

## Restrictions

- **Avoid branch operations** unless explicitly requested by the user
- **Never force push** or perform destructive operations
- **Always ask for confirmation** before commits that affect multiple files
"@

# Write separate git instructions file using the recognized '*.instructions.md' pattern
$gitInstructions | Out-File -FilePath $gitInstructionsPath -Encoding utf8 -Force
Write-Success "Created git.instructions.md"

# Write separate git usage instructions file (detailed tool behavior)
$gitUsageInstructionsPath = Join-Path $githubDir "git.usage.instructions.md"
$gitUsageInstructions = @"
---
name: MCP Git tool usage patterns
description: Tooling usage patterns and limitations when using Git in Agent mode
---

# Git MCP Usage Instructions

These instructions are based on analysis of the Git MCP tools behavior in this workspace.

## Git Diff

The ``git_diff`` tool's ``target`` parameter has specific behaviors:

1.  **Supported Formats:**
    *   **Single SHA/Ref:** Passing a single commit SHA or ref (e.g., ``34c6f6``) works and acts like ``git diff <commit>``. It shows the changes introduced by that commit (effectively the same as ``git show <commit>``).
    *   **Unsupported Formats:** The tool does **NOT** appear to support standard ``git diff`` range syntaxes such as:
        *   ``SHA1..SHA2`` (double dot)
        *   ``SHA1...SHA2`` (triple dot)
        *   ``SHA1 SHA2`` (space separated)
    *   **Error Message:** When an unsupported format is used, the tool returns generic errors like ``Ref '...' did not resolve to an object``.

2.  **Usage Strategy:**
    *   To see changes in a specific commit: Use ``git_diff`` (or ``git_show``) with the single commit SHA.
    *   To compare two commits: Since the tool doesn't support ranges, you cannot directly diff two arbitrary commits using ``git_diff``. You may need to inspect individual commits or use ``git_diff`` with a single SHA to see what *that* commit changed relative to its parent. 
    *   **Note:** The behavior of ``target`` seems synonymous with providing a single "committish" argument to ``git show`` or ``git diff`` where it implies "diff this commit against its parent".

## Git Show

The ``git_show`` tool allows viewing commit details and file contents, but has specific path resolution rules:

1.  **Commit Details:**
    *   You can view full commit details (metadata + full diff) by passing just the SHA to the ``revision`` parameter.
    *   Example: ``revision: "d66833fe4bae2280ea8f9eb8fb91c4b1409336f6"``

2.  **File Content at Revision:** 
    *   **NOT Supported:** The standard ``git show SHA:path/to/file`` syntax does **NOT** work. It returns errors like ``"Blob or Tree named 'filename^0' not found"``.
    *   **Implication:** You cannot easily retrieve the full content of a specific file at a past revision using ``git_show`` with the ``SHA:path`` syntax.
    *   **Workaround:** To see what changed in a file, view the commit diff (using the SHA). If you need the full file content, you might have to checkout that commit (risky/disruptive) or rely on the diff context.

3.  **Diff Filtering:**
    *   ``git_show`` does not accept a ``file_path`` argument to filter the diff of a commit to a specific file. It returns the *entire* diff for that commit. You must parse the output to find the specific file you are interested in.

## General Best Practices

*   **Avoid Complex Refs:** Stick to simple SHAs or clear branch names. Avoid ``..`` or ``...`` ranges in MCP tool arguments unless explicitly documented as supported.
*   **Repo Path:** Always provide the full absolute path to the repository in ``repo_path``.
*   **Checkout Safety:** Be careful with ``git_checkout`` if there are unstaged changes. Use ``git_status`` first.
*   **Large Diffs:** Since ``git_show`` returns the full diff, be prepared for large outputs. Use ``grep`` or specific ``read_file`` strategies if you only need small pieces, though ``git_show`` doesn't support reading partial diffs natively via the tool.

## Summary of Tool Capabilities based on Testing

| Task | Tool | Syntax/Parameter | Status |
| :--- | :--- | :--- | :--- |
| **Show Commit Diff** | ``git_show`` | ``revision: "SHA"`` | ✅ Works |
| **Show Commit Diff** | ``git_diff`` | ``target: "SHA"`` | ✅ Works (Equivalent to Show) |
| **Diff Range (..)** | ``git_diff`` | ``target: "SHA1..SHA2"`` | ❌ Fails |
| **Diff Range (...)** | ``git_diff`` | ``target: "SHA1...SHA2"`` | ❌ Fails |
| **Diff Range (space)**| ``git_diff`` | ``target: "SHA1 SHA2"`` | ❌ Fails |
| **File at Revision** | ``git_show`` | ``revision: "SHA:path/file"``| ❌ Fails |
| **File at Revision** | ``git_show`` | ``revision: "SHA:./file"`` | ❌ Fails |
"@

$gitUsageInstructions | Out-File -FilePath $gitUsageInstructionsPath -Encoding utf8 -Force
Write-Success "Created git.usage.instructions.md"

# Final summary
Write-Host @"

╔═══════════════════════════════════════════════════════╗
║              Setup Complete! ✓                        ║
╚═══════════════════════════════════════════════════════╝

"@ -ForegroundColor Green

Write-Host "Installation Summary:" -ForegroundColor Cyan
Write-Host "  • Python:      " -NoNewline; Write-Host $PythonDir -ForegroundColor White
Write-Host "  • MCP Server:  " -NoNewline; Write-Host $GitServerExe -ForegroundColor White
Write-Host "  • Config:      " -NoNewline; Write-Host $mcpJsonPath -ForegroundColor White
Write-Host ""
Write-Host "Next Steps:" -ForegroundColor Cyan
Write-Host "  1. Restart VS Code or reload the window (Ctrl+Shift+P → 'Developer: Reload Window')"
Write-Host "  2. Open the MCP panel to verify the 'git' server is running"
Write-Host "  3. Configure tool auto-approvals in Copilot settings"
Write-Host ""
Write-Host "To use in other projects:" -ForegroundColor Cyan
Write-Host "  • Run this script from each project directory"
Write-Host "  • The MCP server is already installed, only config will be created"
Write-Host ""
