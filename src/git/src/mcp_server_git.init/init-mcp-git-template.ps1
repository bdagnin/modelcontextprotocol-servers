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

# <<EMBEDDED_FILES_PLACEHOLDER>>

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

function Install-EmbeddedFiles {
    <#
    .SYNOPSIS
        Installs embedded files to the workspace preserving relative paths.
    
    .PARAMETER DestinationRoot
        The root directory where files should be installed.
    
    .PARAMETER Files
        Array of hashtables containing RelativePath and Content properties.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$DestinationRoot,
        
        [Parameter(Mandatory=$true)]
        [array]$Files
    )
    
    $installedCount = 0
    $skippedCount = 0
    
    foreach ($file in $Files) {
        $targetPath = Join-Path $DestinationRoot $file.RelativePath
        $targetDir = Split-Path -Parent $targetPath
        
        # Create directory if it doesn't exist
        if (-not (Test-Path $targetDir)) {
            New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        }
        
        # Check if file already exists
        if (Test-Path $targetPath) {
            $existingContent = Get-Content $targetPath -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
            if ($existingContent -eq $file.Content) {
                $skippedCount++
                continue
            }
        }
        
        # Write file
        try {
            $file.Content | Out-File -FilePath $targetPath -Encoding utf8 -Force
            $installedCount++
            Write-Info "Installed: $($file.RelativePath)"
        } catch {
            Write-Host "  ✗ Failed to install file $($file.RelativePath): $_" -ForegroundColor Red
        }
    }
    
    if ($installedCount -gt 0) {
        Write-Success "Installed $installedCount file(s)"
    }
    if ($skippedCount -gt 0) {
        Write-Info "Skipped $skippedCount unchanged file(s)"
    }
}

function Update-GitIgnoreFiles {
    <#
    .SYNOPSIS
        Creates or updates .gitignore files to ignore installed files.
    
    .PARAMETER DestinationRoot
        The root directory where files were installed.
    
    .PARAMETER Files
        Array of hashtables containing RelativePath properties.
    #>
    param(
        [Parameter(Mandatory=$true)]
        [string]$DestinationRoot,
        
        [Parameter(Mandatory=$true)]
        [array]$Files
    )
    
    # Group files by their parent directory
    $filesByParent = @{}
    foreach ($file in $Files) {
        $parent = Split-Path -Parent $file.RelativePath
        if (-not $parent) { $parent = "." }
        
        if (-not $filesByParent.ContainsKey($parent)) {
            $filesByParent[$parent] = @()
        }
        $filesByParent[$parent] += Split-Path -Leaf $file.RelativePath
    }
    
    # Find the highest directory in each subtree that contains files
    # Remove any directory whose parent also has files (since parent's .gitignore will cover it)
    $highestDirs = @{}
    
    foreach ($dir in $filesByParent.Keys | Sort-Object) {
        $isHighest = $true
        
        # Check if any parent directory also has files
        $parentDir = Split-Path -Parent $dir
        while ($parentDir -and $parentDir -ne ".") {
            if ($filesByParent.ContainsKey($parentDir)) {
                # Parent has files, so it will have a .gitignore that covers us
                $isHighest = $false
                break
            }
            $parentDir = Split-Path -Parent $parentDir
        }
        
        # Special case: if dir is "." (root), it's highest
        if ($dir -eq ".") {
            $isHighest = $true
        }
        
        if ($isHighest) {
            $highestDirs[$dir] = $true
        }
    }
    
    # For each highest directory, collect all items to ignore
    foreach ($dir in $highestDirs.Keys) {
        $dirFullPath = if ($dir -eq ".") { $DestinationRoot } else { Join-Path $DestinationRoot $dir }
        $gitignorePath = Join-Path $dirFullPath ".gitignore"
        
        # Collect all files and subdirectories under this dir that we installed
        $entries = @()
        
        # Add direct files in this directory
        if ($filesByParent.ContainsKey($dir)) {
            $entries += $filesByParent[$dir]
        }
        
        # Add subdirectories that contain our files
        $dirPrefix = if ($dir -eq ".") { "" } else { $dir + "\" }
        foreach ($otherDir in $filesByParent.Keys) {
            if ($otherDir -ne $dir -and $otherDir.StartsWith($dirPrefix)) {
                # This is a subdirectory of $dir
                $relativePath = $otherDir.Substring($dirPrefix.Length)
                $topLevelSubdir = $relativePath -split '[\\/]' | Select-Object -First 1
                if ($topLevelSubdir -and $entries -notcontains $topLevelSubdir) {
                    $entries += $topLevelSubdir + "/"
                }
            }
        }
        
        $entries = $entries | Select-Object -Unique | Sort-Object
        
        if ($entries.Count -eq 0) { continue }
        
        # Create or update .gitignore
        if (Test-Path $gitignorePath) {
            # Patch existing .gitignore
            $existingContent = Get-Content $gitignorePath -Raw -ErrorAction SilentlyContinue
            if (-not $existingContent) { $existingContent = "" }
            
            $newEntries = @()
            foreach ($entry in $entries) {
                # Check if entry already exists (exact line match or pattern match)
                $escaped = [regex]::Escape($entry.TrimEnd('/'))
                if ($existingContent -notmatch "(?m)^/?$escaped/?\\s*$") {
                    $newEntries += $entry
                }
            }
            
            if ($newEntries.Count -gt 0) {
                $separator = if ($existingContent.Trim()) { "`n`n" } else { "" }
                $content = $separator + "# MCP Git Server installed files`n" + ($newEntries -join "`n")
                Add-Content -Path $gitignorePath -Value $content -NoNewline
                $displayDir = if ($dir -eq ".") { "(root)" } else { $dir }
                Write-Info "Patched .gitignore in $displayDir ($($newEntries.Count) entries)"
            } else {
                $displayDir = if ($dir -eq ".") { "(root)" } else { $dir }
                Write-Info "Skipped .gitignore in $displayDir (entries already present)"
            }
        } else {
            # Create new .gitignore (self-ignore at the top)
            $allEntries = @(".gitignore") + $entries
            $content = "# MCP Git Server installed files`n" + ($allEntries -join "`n") + "`n"
            $content | Out-File -FilePath $gitignorePath -Encoding utf8 -Force
            $displayDir = if ($dir -eq ".") { "(root)" } else { $dir }
            Write-Success "Created .gitignore in $displayDir"
        }
    }
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
$gitignoreEntries = @(".gitignore", ".vscode/mcp.json")

if (Test-Path $gitignorePath) {
    $gitignoreContent = Get-Content $gitignorePath -Raw
    $newEntries = @()
    foreach ($entry in $gitignoreEntries) {
        $escaped = [regex]::Escape($entry)
        if ($gitignoreContent -notmatch "(?m)^/?$escaped/?\\s*$") {
            $newEntries += $entry
        }
    }
    
    if ($newEntries.Count -gt 0) {
        $separator = if ($gitignoreContent.Trim()) { "`n`n" } else { "" }
        $content = $separator + "# MCP configuration (machine-specific)`n" + ($newEntries -join "`n")
        Add-Content -Path $gitignorePath -Value $content
        Write-Success "Added $($newEntries.Count) entries to .gitignore"
    } else {
        Write-Info "All entries already in .gitignore"
    }
} else {
    $content = "# MCP configuration (machine-specific)`n" + ($gitignoreEntries -join "`n") + "`n"
    $content | Out-File -FilePath $gitignorePath -Encoding utf8
    Write-Success "Created .gitignore with MCP entries"
}

# Install embedded files (skills and prompts)
Write-Step "Installing Copilot skills and prompts"
try {
    Install-EmbeddedFiles -DestinationRoot $workspaceFolder -Files $EmbeddedFiles
    Update-GitIgnoreFiles -DestinationRoot $workspaceFolder -Files $EmbeddedFiles
} catch {
    Write-Host "  ✗ Failed to install embedded files: $_" -ForegroundColor Red
    # Don't exit - this is not critical
}

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
