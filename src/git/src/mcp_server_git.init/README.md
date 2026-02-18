# MCP Git Server Initialization Script

This directory contains the automated setup script for the MCP Git Server along with supporting files.

## Files

- **`init-mcp-git.ps1`** - The main initialization script (compiled/generated - do not edit directly)
- **`init-mcp-git-template.ps1`** - The source template for the initialization script
- **`build-init-script.ps1`** - Builder script that compiles the template and embedded files into init-mcp-git.ps1
- **`skills/`** - Copilot skill definitions (embedded into the compiled script)
- **`.github/prompts/`** - Copilot prompt definitions (embedded into the compiled script)

## For Users

Simply run the initialization script:

```powershell
.\init-mcp-git.ps1
```

This will:
1. Download and configure a portable Python environment
2. Install the `mcp-server-git` package
3. Create workspace-specific MCP configuration in `.vscode/mcp.json`
4. Install Copilot skills and prompts into your workspace

## For Developers

### Making Changes

1. **Edit the template**: Make changes to `init-mcp-git-template.ps1` (not the main script)
2. **Edit embedded files**: Modify files in `skills/` or `.github/prompts/`
3. **Rebuild**: Run the builder script to compile changes into init-mcp-git.ps1:
   ```powershell
   .\build-init-script.ps1
   ```
4. **Test**: Run the generated `init-mcp-git.ps1` to verify changes

### Build Process

The build script (`build-init-script.ps1`):
- Reads the template file (`init-mcp-git-template.ps1`)
- Recursively collects all files from `skills/` and `.github/prompts/`
- Embeds file contents as PowerShell data structures
- Outputs the compiled script directly to `init-mcp-git.ps1`

The compiled script:
- Contains all external files embedded as strings
- Uses the `Install-EmbeddedFiles` function to deploy files to the workspace
- Preserves relative paths from the workspace root

### Adding New Files

To add new skill or prompt files:
1. Create the file in the appropriate directory (`skills/` or `.github/prompts/`)
2. Rebuild using `.\build-init-script.ps1`
3. The new files will automatically be embedded and installed

### Template Placeholders

The template contains the marker:
```
# <<EMBEDDED_FILES_PLACEHOLDER>>
```

This is replaced during build with the embedded files data structure.
