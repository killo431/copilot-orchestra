#!/bin/bash

###############################################################################
# GitHub Copilot Orchestra - Automatic Environment Setup
# 
# This script automatically sets up the development environment when the
# repository is opened in VSCode.
###############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Setup flag file to prevent multiple runs
SETUP_FLAG=".setup_complete"

# Function to print colored output
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

print_section() {
    echo ""
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}"
}

# Check if setup has already been completed
if [ -f "$SETUP_FLAG" ]; then
    print_info "Setup has already been completed."
    print_info "To re-run setup, delete the '$SETUP_FLAG' file."
    exit 0
fi

print_section "GitHub Copilot Orchestra - Environment Setup"

echo ""
print_info "This script will set up your development environment automatically."
echo ""

# Check prerequisites
print_section "Checking Prerequisites"

# Check Git
if command -v git &> /dev/null; then
    GIT_VERSION=$(git --version | cut -d' ' -f3)
    print_success "Git is installed (version $GIT_VERSION)"
else
    print_error "Git is not installed"
    print_info "Please install Git from: https://git-scm.com/downloads"
    exit 1
fi

# Check if this is a git repository
if [ -d .git ]; then
    print_success "Git repository initialized"
else
    print_warning "Not a git repository, initializing..."
    git init
    print_success "Git repository initialized"
fi

# Check Node.js (optional but recommended)
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    print_success "Node.js is installed ($NODE_VERSION)"
else
    print_warning "Node.js is not installed (optional for this project)"
    print_info "Install from: https://nodejs.org/"
fi

# Check Python
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version | cut -d' ' -f2)
    print_success "Python 3 is installed (version $PYTHON_VERSION)"
else
    print_warning "Python 3 is not installed (optional for indexer)"
    print_info "Install from: https://www.python.org/downloads/"
fi

# Check Docker
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | tr -d ',')
    print_success "Docker is installed (version $DOCKER_VERSION)"
    
    # Check Docker Compose
    if docker compose version &> /dev/null; then
        COMPOSE_VERSION=$(docker compose version | cut -d' ' -f4)
        print_success "Docker Compose is installed (version $COMPOSE_VERSION)"
    else
        print_warning "Docker Compose is not installed (optional for indexer)"
        print_info "Install from: https://docs.docker.com/compose/install/"
    fi
else
    print_warning "Docker is not installed (optional for indexer)"
    print_info "Install from: https://docs.docker.com/get-docker/"
fi

# Create necessary directories
print_section "Creating Project Directories"

DIRS=("plans" "examples" "templates" "tools" "docs" ".vscode")

for dir in "${DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        print_success "Created directory: $dir"
    else
        print_info "Directory already exists: $dir"
    fi
done

# Setup plans directory for Conductor agent
if [ ! -d "plans" ]; then
    mkdir -p plans
    print_success "Created plans directory for Conductor agent"
fi

# Create .gitignore if it doesn't exist
print_section "Configuring Git"

if [ ! -f .gitignore ]; then
    cat > .gitignore << 'EOF'
# OS files
.DS_Store
Thumbs.db
*~

# IDE files
.vscode/settings.local.json
.idea/
*.swp
*.swo

# Logs
*.log
logs/

# Environment variables
.env
.env.local
.env.*.local

# Dependencies
node_modules/
venv/
env/
ENV/
__pycache__/
*.pyc
*.pyo

# Build outputs
dist/
build/
*.egg-info/
.pytest_cache/
coverage/

# Indexer
indexer/chroma_db/
indexer/.env

# Optional: Uncomment to exclude plans from version control
# plans/
EOF
    print_success "Created .gitignore file"
else
    print_info ".gitignore already exists"
fi

# Setup agent files location reminder
print_section "Custom Agent Files"

echo ""
print_info "Custom agent files (.agent.md) are located in the project root:"
print_info "  • Conductor.agent.md"
print_info "  • planning-subagent.agent.md"
print_info "  • implement-subagent.agent.md"
print_info "  • code-review-subagent.agent.md"
print_info "  • quality-assurance-subagent.agent.md"
echo ""
print_info "These files need to be available in VSCode Insiders to use the agents."
print_info "See README.md for installation instructions."

# Check if running in VSCode
print_section "VSCode Integration"

if [ -n "$VSCODE_PID" ] || [ -n "$TERM_PROGRAM" ] && [ "$TERM_PROGRAM" = "vscode" ]; then
    print_success "Running in VSCode"
    
    # Check for recommended extensions
    print_info "Recommended extensions are defined in .vscode/extensions.json"
    print_info "VSCode will prompt you to install them automatically"
else
    print_info "Not running in VSCode"
    print_info "Open this project in VSCode for the best experience"
fi

# Setup indexer environment
print_section "RAG Indexer Setup"

if [ -d "indexer" ]; then
    print_success "Indexer directory found"
    
    if [ ! -f "indexer/.env" ]; then
        if [ -f "indexer/.env.example" ]; then
            cp indexer/.env.example indexer/.env
            print_success "Created indexer/.env from template"
            print_warning "Remember to add your OPENAI_API_KEY to indexer/.env"
        else
            print_warning "indexer/.env.example not found"
        fi
    else
        print_info "indexer/.env already exists"
    fi
else
    print_info "Indexer not found (may not be needed for your use case)"
fi

# Display welcome message
print_section "Setup Complete!"

echo ""
print_success "Environment setup completed successfully!"
echo ""
print_info "Next steps:"
echo ""
echo "  1. Open GitHub Copilot Chat in VSCode"
echo "  2. Select the 'Conductor' agent from the chat mode dropdown"
echo "  3. Start building with AI assistance!"
echo ""
print_info "Quick links:"
echo "  • Quick Start Guide: ./QUICKSTART.md"
echo "  • Architecture: ./ARCHITECTURE.md"
echo "  • FAQ: ./FAQ.md"
echo "  • Examples: ./examples/"
echo ""

if [ -d "indexer" ]; then
    echo ""
    print_info "To set up the RAG indexer:"
    echo "  1. Add your OpenAI API key to indexer/.env"
    echo "  2. Run: cd indexer && ./setup.sh"
    echo "  3. See docs/RAG-INDEXER.md for details"
    echo ""
fi

# Create setup flag file
touch "$SETUP_FLAG"
echo "Setup completed on: $(date)" > "$SETUP_FLAG"

print_info "Setup flag created at: $SETUP_FLAG"
print_info "Delete this file to re-run setup."

echo ""
print_section "Happy Coding! 🚀"
echo ""
