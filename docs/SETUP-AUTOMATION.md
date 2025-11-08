# Setup Automation Guide

This document explains the automatic environment setup feature added to GitHub Copilot Orchestra.

## Overview

The repository now includes an automatic setup system that configures the development environment when the workspace is opened in VSCode.

## Components

### 1. Setup Script (`setup-environment.sh`)

Main automation script that:
- ✅ Verifies prerequisites (Git, Node.js, Python, Docker)
- ✅ Creates necessary project directories
- ✅ Configures Git settings
- ✅ Sets up indexer environment
- ✅ Checks for VSCode integration
- ✅ Creates a setup completion flag to prevent re-runs

**Location**: `/setup-environment.sh`

**Usage**:
```bash
# Run automatically on workspace open (via VSCode task)
# Or run manually:
./setup-environment.sh

# To re-run setup:
rm .setup_complete && ./setup-environment.sh
```

### 2. VSCode Tasks (`.vscode/tasks.json`)

Automated tasks including:

- **Auto Setup Environment** - Runs automatically when workspace is opened
- **Setup Environment (Manual)** - Manual trigger
- **Reset and Re-run Setup** - Clears flag and re-runs
- **Setup RAG Indexer** - Configures the indexer
- **Build Indexer Docker Image** - Builds Docker image
- **Run Indexer** - Starts indexing
- **Stop Indexer** - Stops the indexer
- **View Project Documentation** - Opens key docs

**Access**: `Cmd+Shift+P` → "Tasks: Run Task"

### 3. Welcome Guide (`WELCOME.md`)

User-friendly welcome document that:
- Explains what happened during setup
- Provides quick start instructions
- Links to essential documentation
- Lists available tasks

**Auto-displayed**: Opens after first setup (optional)

### 4. Updated VSCode Settings

Enhanced `.vscode/settings.json` with:
- Task auto-detection enabled
- Additional spell check words (chroma, langchain, etc.)
- File watcher exclusions for performance
- Agent file associations

## How It Works

### First Time Setup

1. User clones repository
2. Opens in VSCode Insiders
3. Automatic task triggers `setup-environment.sh`
4. Script checks prerequisites and configures environment
5. Creates `.setup_complete` flag
6. Welcome guide displayed (optional)

### Subsequent Opens

1. User opens workspace
2. Script detects `.setup_complete` flag
3. Skips setup with informational message
4. Ready to use immediately

### Manual Re-run

```bash
# Method 1: Delete flag and run
rm .setup_complete
./setup-environment.sh

# Method 2: Use VSCode task
# Cmd+Shift+P → "Tasks: Run Task" → "Reset and Re-run Setup"
```

## Features

### Intelligent Detection

- **Git**: Checks version and repo status
- **Node.js**: Detects version (optional)
- **Python**: Detects version (optional for indexer)
- **Docker**: Checks Docker and Docker Compose (optional for indexer)
- **VSCode**: Detects if running in VSCode

### Directory Management

Creates essential directories:
- `plans/` - For Conductor agent documentation
- `examples/` - For usage examples
- `templates/` - For custom configurations
- `tools/` - For automation scripts
- `docs/` - For documentation
- `.vscode/` - For VSCode settings

### Environment Configuration

- Creates `.gitignore` if missing
- Sets up `indexer/.env` from template
- Configures Git settings
- Prepares agent files

### User Guidance

- Color-coded output (success, warning, error, info)
- Clear next steps
- Links to documentation
- Task recommendations

## Customization

### Modifying the Setup Script

Edit `setup-environment.sh` to:
- Add custom checks
- Create additional directories
- Install dependencies
- Configure tools

Example:
```bash
# Add custom step
print_section "Custom Setup Step"

if [ ! -f "custom-config.json" ]; then
    echo '{"setting": "value"}' > custom-config.json
    print_success "Created custom configuration"
fi
```

### Adding VSCode Tasks

Edit `.vscode/tasks.json`:

```json
{
  "label": "My Custom Task",
  "type": "shell",
  "command": "echo 'Custom command'",
  "options": {
    "cwd": "${workspaceFolder}"
  },
  "presentation": {
    "reveal": "always",
    "panel": "shared"
  }
}
```

### Disabling Auto-Setup

To disable automatic setup on workspace open:

1. Edit `.vscode/tasks.json`
2. Remove or comment out the `"runOptions"` section from "Auto Setup Environment" task:

```json
// "runOptions": {
//   "runOn": "folderOpen"
// }
```

## Troubleshooting

### Setup Runs Every Time

**Problem**: Setup script runs on every workspace open

**Solution**: Check if `.setup_complete` exists:
```bash
ls -la .setup_complete
```

If missing, the script will run. Ensure it's not in `.gitignore` incorrectly.

### Task Doesn't Run Automatically

**Problem**: Auto-setup task doesn't trigger on workspace open

**Solution**:
1. Check VSCode settings: `"task.autoDetect": "on"`
2. Verify `.vscode/tasks.json` has correct `runOptions`
3. Try reloading VSCode: `Cmd+Shift+P` → "Reload Window"

### Permission Denied

**Problem**: `./setup-environment.sh: Permission denied`

**Solution**:
```bash
chmod +x setup-environment.sh
```

### Prerequisites Missing

**Problem**: Setup reports missing prerequisites

**Solution**: Install the required tools:
- Git: https://git-scm.com/downloads
- Node.js: https://nodejs.org/ (optional)
- Python: https://www.python.org/downloads/ (optional)
- Docker: https://docs.docker.com/get-docker/ (optional)

## Best Practices

### For Repository Maintainers

1. **Keep setup.sh Updated**: Maintain as project requirements change
2. **Document Prerequisites**: Update README with required versions
3. **Test Regularly**: Run setup on fresh clones periodically
4. **Version Tasks**: Track task changes in git

### For Contributors

1. **Run Setup First**: Let automatic setup configure environment
2. **Report Issues**: Open issues if setup fails
3. **Check Flag**: Delete `.setup_complete` if environment is corrupted
4. **Read Welcome**: Follow guidance in WELCOME.md

### For Team Leads

1. **Onboarding**: New team members just clone and open in VSCode
2. **Consistency**: Everyone gets the same environment setup
3. **Documentation**: Welcome guide provides instant orientation
4. **Standards**: Tasks enforce consistent workflows

## Security Considerations

### What the Script Does

- ✅ Creates directories and files
- ✅ Reads environment variables
- ✅ Checks command availability
- ✅ Copies template files

### What It Doesn't Do

- ❌ Doesn't install software
- ❌ Doesn't modify system files
- ❌ Doesn't send data anywhere
- ❌ Doesn't require sudo/admin

### Environment Files

- `.env` files are created from templates
- Users must add their own API keys
- Never commit `.env` files
- Always use `.env.example` as template

## Advanced Usage

### CI/CD Integration

Use the setup script in CI pipelines:

```yaml
# GitHub Actions example
- name: Setup Environment
  run: |
    chmod +x setup-environment.sh
    ./setup-environment.sh
```

### Docker Integration

Include in Dockerfile for containerized development:

```dockerfile
FROM node:20
WORKDIR /app
COPY . .
RUN chmod +x setup-environment.sh && ./setup-environment.sh
```

### Custom Hooks

Add Git hooks to run on clone:

```bash
# .git/hooks/post-checkout
#!/bin/bash
if [ ! -f .setup_complete ]; then
    ./setup-environment.sh
fi
```

## Future Enhancements

Potential improvements:

1. **Interactive Mode**: Ask user preferences during setup
2. **Profile Selection**: Different setups for different roles
3. **Dependency Installation**: Optionally install tools
4. **Health Checks**: Periodic environment validation
5. **Update Detection**: Check for setup script updates
6. **Telemetry**: Optional usage analytics (with consent)

## Related Documentation

- [README.md](../README.md) - Main project documentation
- [WELCOME.md](../WELCOME.md) - Welcome guide for new users
- [QUICKSTART.md](../QUICKSTART.md) - Quick start guide
- [TROUBLESHOOTING.md](../TROUBLESHOOTING.md) - Troubleshooting guide

## Support

For issues with the setup automation:

1. Check this guide for solutions
2. Review [TROUBLESHOOTING.md](../TROUBLESHOOTING.md)
3. Open an issue on GitHub with:
   - Your OS and versions
   - Setup script output
   - Error messages

---

**Last Updated**: 2025-11-08
