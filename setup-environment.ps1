<#
.SYNOPSIS
  Interactive Windows desktop environment setup script for developers.

.DESCRIPTION
  This script prepares a Windows developer workstation by:
    - Ensuring it's run elevated (offers to re-run as Administrator)
    - Setting ExecutionPolicy to RemoteSigned for the current user
    - Installing Chocolatey (optionally) if missing
    - (Alternatively uses winget if user prefers)
    - Installing a curated list of common developer packages (git, nodejs-lts, python, vscode, 7zip, googlechrome, windows-terminal, docker-desktop, etc.)
    - Optionally installing VS Code extensions and setting Git global config
    - Optionally enabling WSL 2 (requires reboot)
    - Creating a Python virtualenv template location (optional)
    - Idempotent (will skip already-installed items) and logs progress

.NOTES
  - Run in an elevated PowerShell session (the script will try to elevate itself if not).
  - Requires internet access.
  - Docker Desktop installation requires virtualization enabled and a reboot in some cases.
  - This script is interactive; you can run it with -NonInteractive switch to accept defaults.

.EXAMPLE
  .\setup-environment.ps1
  .\setup-environment.ps1 -NonInteractive

#>

param(
  [switch]$NonInteractive,
  [switch]$SkipChocolatey,
  [switch]$InstallWSL,
  [string[]]$ExtraPackages = @()
)

Set-StrictMode -Version Latest
$ProgressPreference = 'SilentlyContinue'

function Write-Info { param($m) Write-Host "[INFO]  $m" -ForegroundColor Cyan }
function Write-Warn { param($m) Write-Host "[WARN]  $m" -ForegroundColor Yellow }
function Write-ErrorAndExit { param($m) Write-Host "[ERROR] $m" -ForegroundColor Red; Exit 1 }

# Ensure elevated
function Ensure-RunAsAdmin {
  $isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
  if (-not $isAdmin) {
    if ($NonInteractive) {
      Write-ErrorAndExit "This script must be run as Administrator in non-interactive mode."
    }
    Write-Info "Not running as Administrator. Attempting to relaunch elevated..."
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell.exe"
    $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `$PSCommandPath` $($MyInvocation.Line.Substring($MyInvocation.Line.IndexOf($PSCommandPath) + $PSCommandPath.Length))"
    $psi.Verb = "runas"
    try {
      [System.Diagnostics.Process]::Start($psi) | Out-Null
      Exit 0
    } catch {
      Write-ErrorAndExit "Elevation cancelled or failed. Please re-run this script as Administrator."
    }
  } else {
    Write-Info "Running as Administrator."
  }
}

function Set-ExecutionPolicyIfNeeded {
  try {
    $current = Get-ExecutionPolicy -Scope CurrentUser -ErrorAction Stop
  } catch {
    $current = "Undefined"
  }
  if ($current -ne 'RemoteSigned' -and $current -ne 'Unrestricted') {
    Write-Info "Setting ExecutionPolicy for CurrentUser to RemoteSigned."
    try {
      Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
    } catch {
      Write-Warn "Failed to set ExecutionPolicy: $_"
    }
  } else {
    Write-Info "ExecutionPolicy for CurrentUser is already $current."
  }
}

function Use-WingetAvailable {
  try {
    winget -v > $null 2>&1
    return $true
  } catch {
    return $false
  }
}

function Install-Chocolatey {
  if ($SkipChocolatey) {
    Write-Info "Skipping Chocolatey installation by request."
    return $false
  }
  if (Get-Command choco -ErrorAction SilentlyContinue) {
    Write-Info "Chocolatey is already installed."
    return $true
  }
  Write-Info "Installing Chocolatey..."
  try {
    Set-ExecutionPolicy Bypass -Scope Process -Force
    $chocoScript = "https://community.chocolatey.org/install.ps1"
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString($chocoScript))
    if (Get-Command choco -ErrorAction SilentlyContinue) {
      Write-Info "Chocolatey installed successfully."
      return $true
    } else {
      Write-Warn "Chocolatey install didn't complete or is not on PATH."
      return $false
    }
  } catch {
    Write-Warn "Chocolatey install failed: $_"
    return $false
  }
}

function Install-Packages {
  param(
    [string[]]$PackagesToInstall
  )
  if (Get-Command choco -ErrorAction SilentlyContinue) {
    foreach ($pkg in $PackagesToInstall) {
      Write-Info "Ensuring package: $pkg (choco)"
      $installed = choco list --local-only --exact $pkg 2>$null | Select-String "^$pkg" 
      if ($installed) {
        Write-Info "  $pkg already installed (choco)."
      } else {
        Write-Info "  Installing $pkg via choco..."
        choco install $pkg -y --no-progress
      }
    }
  } elseif (Use-WingetAvailable) {
    foreach ($pkg in $PackagesToInstall) {
      Write-Info "Ensuring package: $pkg (winget)"
      try {
        $found = winget list --name $pkg 2>$null
        if ($found -and -not ($found -match 'No installed package found')) {
          Write-Info "  $pkg already installed (winget)."
        } else {
          Write-Info "  Installing $pkg via winget..."
          winget install --id $pkg -e --accept-source-agreements --accept-package-agreements
        }
      } catch {
        Write-Warn "  winget handling for $pkg failed: $_"
      }
    }
  } else {
    Write-Warn "No supported package manager found (choco or winget). Install packages manually: $($PackagesToInstall -join ', ')"
  }
}

function Install-VSCodeExtensions {
  $extensions = @(
    "ms-python.python",
    "esbenp.prettier-vscode",
    "dbaeumer.vscode-eslint",
    "ms-vscode.cpptools"
  )
  # Allow user to extend
  $more = Read-Host "Add additional VS Code extensions (comma-separated) or press Enter"
  if ($more) {
    $extensions += ($more -split ',') | ForEach-Object { $_.Trim() } | Where-Object { $_ }
  }
  $codeCmd = Get-Command code -ErrorAction SilentlyContinue
  if (-not $codeCmd) {
    Write-Warn "VS Code 'code' CLI not found on PATH. You can open VS Code -> Command Palette -> 'Shell Command: Install 'code' command in PATH'. Skipping extension installation."
    return
  }
  foreach ($ext in $extensions) {
    Write-Info "Installing VS Code extension: $ext"
    & code --install-extension $ext --force
  }
}

function Configure-Git {
  if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Warn "git not found; skipping git configuration."
    return
  }
  $currentName = git config --global user.name 2>$null
  $currentEmail = git config --global user.email 2>$null
  if (-not $currentName) {
    $name = if ($NonInteractive) { "Your Name" } else { Read-Host "Git user.name (global)?" }
    if ($name) { git config --global user.name $name; Write-Info "Set git user.name = $name" }
  } else {
    Write-Info "Git user.name already set: $currentName"
  }
  if (-not $currentEmail) {
    $email = if ($NonInteractive) { "you@example.com" } else { Read-Host "Git user.email (global)?" }
    if ($email) { git config --global user.email $email; Write-Info "Set git user.email = $email" }
  } else {
    Write-Info "Git user.email already set: $currentEmail"
  }
  # Helpful defaults
  git config --global init.defaultBranch main
  git config --global core.autocrlf true
  Write-Info "Set some helpful global git defaults (init.defaultBranch=main, core.autocrlf=true)."
}

function Enable-WSL2 {
  Write-Info "Enabling WSL and Virtual Machine Platform (may require reboot)."
  try {
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart | Out-Null
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart | Out-Null
    Write-Info "WSL features enabled. To complete WSL install, run: wsl --install (may require reboot)."
  } catch {
    Write-Warn "Failed enabling WSL features: $_"
  }
}

function Setup-PythonVirtualEnvTemplate {
  $templateDir = "$env:USERPROFILE\dev\venv-templates"
  if (-not (Test-Path $templateDir)) {
    New-Item -Type Directory -Path $templateDir -Force | Out-Null
    Write-Info "Created python virtualenv templates directory: $templateDir"
  } else {
    Write-Info "Python virtualenv templates directory already exists: $templateDir"
  }
}

# Main flow
Ensure-RunAsAdmin
Set-ExecutionPolicyIfNeeded

$defaultPackages = @(
  # Chocolatey package IDs (or winget Ids can be used in the ExtraPackages param)
  "git",
  "nodejs-lts",
  "python",
  "vscode",
  "7zip",
  "googlechrome",
  "windows-terminal",
  "docker-desktop"
)
if ($ExtraPackages) {
  $toInstall = $defaultPackages + $ExtraPackages
} else {
  $toInstall = $defaultPackages
}

# Install Chocolatey (or skip if not desired)
$haveChoco = $false
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
  if (-not (Use-WingetAvailable)) {
    $haveChoco = Install-Chocolatey
  } else {
    Write-Info "winget available. Will prefer winget if Chocolatey is not installed."
  }
} else {
  $haveChoco = $true
}

# Confirm package installation
if (-not $NonInteractive) {
  Write-Host
  Write-Host "Packages to install: " -NoNewline; Write-Host ($toInstall -join ", ") -ForegroundColor Green
  $resp = Read-Host "Proceed with installation of the above packages? (Y/n)"
  if ($resp -and $resp -match '^[Nn]') {
    Write-Warn "Package installation skipped by user."
  } else {
    Install-Packages -PackagesToInstall $toInstall
  }
} else {
  Install-Packages -PackagesToInstall $toInstall
}

# Configure git
if (-not $NonInteractive) {
  $confGit = Read-Host "Configure git global settings now? (Y/n)"
  if (-not $confGit -or $confGit -match '^[Yy]') { Configure-Git }
} else {
  Configure-Git
}

# VS Code extensions
if (-not $NonInteractive) {
  $installCodeExt = Read-Host "Install common VS Code extensions? (Y/n)"
  if (-not $installCodeExt -or $installCodeExt -match '^[Yy]') { Install-VSCodeExtensions }
} else {
  Install-VSCodeExtensions
}

# WSL
if ($InstallWSL -or ($NonInteractive -and $InstallWSL)) {
  Enable-WSL2
} elseif (-not $NonInteractive) {
  $wslAnswer = Read-Host "Enable WSL2 and Virtual Machine Platform (recommended for Docker Desktop)? (y/N)"
  if ($wslAnswer -and $wslAnswer -match '^[Yy]') {
    Enable-WSL2
  }
}

# Python venv template
Setup-PythonVirtualEnvTemplate

Write-Info "Setup complete. Some installs (e.g., Docker Desktop, WSL) may require a reboot to finish configuring."
Write-Host
Write-Host "Next recommended steps:" -ForegroundColor Green
Write-Host "- Sign into VS Code and install additional extensions as needed."
Write-Host "- Reboot if prompted (Docker Desktop, WSL, or virtualization changes)."
Write-Host "- For Python projects: create a venv and install required packages: python -m venv .venv; .\.venv\Scripts\Activate; pip install -r requirements.txt"
Write-Host "- If 'code' CLI not found: open VS Code -> Command Palette -> 'Shell Command: Install 'code' command in PATH'."