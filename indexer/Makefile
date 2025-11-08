.PHONY: help build run test clean install dev

help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'

build: ## Build the Docker image
	docker compose build

run: ## Run the indexer
	docker compose up

test: ## Run tests
	python tests/test_indexer.py

clean: ## Clean up generated files
	rm -rf chroma_db/
	rm -rf src/__pycache__/
	rm -rf tests/__pycache__/
	docker compose down -v

install: ## Install Python dependencies locally
	pip install -r requirements.txt

dev: install ## Setup development environment
	cp .env.example .env
	@echo "Please edit .env and add your OPENAI_API_KEY"

rebuild: clean build ## Clean and rebuild

logs: ## Show Docker logs
	docker compose logs -f
