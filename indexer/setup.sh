#!/bin/bash

# Quick start script for RAG Indexer setup
set -e

echo "=================================="
echo "RAG Indexer Quick Start Setup"
echo "=================================="
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Error: Docker is not installed"
    echo "Please install Docker from: https://docs.docker.com/get-docker/"
    exit 1
fi

echo "✓ Docker is installed"

# Check if Docker Compose is available
if ! docker compose version &> /dev/null; then
    echo "❌ Error: Docker Compose v2 is not installed"
    echo "Please install Docker Compose from: https://docs.docker.com/compose/install/"
    exit 1
fi

echo "✓ Docker Compose v2 is installed"
echo ""

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "Creating .env file from template..."
    cp .env.example .env
    echo "✓ .env file created"
    echo ""
    echo "⚠️  IMPORTANT: Please edit .env and add your OPENAI_API_KEY"
    echo ""
    echo "Example:"
    echo "  OPENAI_API_KEY=sk-your-actual-key-here"
    echo ""
    read -p "Press Enter after you've added your API key to .env..."
else
    echo "✓ .env file already exists"
fi

echo ""

# Check if OPENAI_API_KEY is set
source .env
if [ -z "$OPENAI_API_KEY" ] || [ "$OPENAI_API_KEY" = "your_openai_api_key_here" ]; then
    echo "❌ Error: OPENAI_API_KEY is not set in .env file"
    echo "Please edit .env and add your actual OpenAI API key"
    exit 1
fi

echo "✓ OPENAI_API_KEY is configured"
echo ""

# Build the Docker image
echo "Building Docker image..."
docker compose build

if [ $? -eq 0 ]; then
    echo "✓ Docker image built successfully"
    echo ""
    echo "=================================="
    echo "Setup Complete! 🎉"
    echo "=================================="
    echo ""
    echo "To run the indexer:"
    echo "  docker compose up"
    echo ""
    echo "To rebuild after changes:"
    echo "  docker compose build"
    echo ""
    echo "To clean up:"
    echo "  make clean"
    echo ""
else
    echo "❌ Error: Docker build failed"
    echo ""
    echo "If you're experiencing SSL certificate errors, try:"
    echo "  1. Building on a different network"
    echo "  2. Using local development setup (see README.md)"
    exit 1
fi
