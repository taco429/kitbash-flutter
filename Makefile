# Default target when just running 'make'
.DEFAULT_GOAL := help

# Variables
BACKEND_DIR := backend
BACKEND_BIN := $(BACKEND_DIR)/bin/server
GO_MAIN := $(BACKEND_DIR)/cmd/server

# Colors for terminal output (works on most Unix terminals)
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

# Help target - displays all available commands
.PHONY: help
help: ## Show this help message
	@echo "$(BLUE)Kitbash Flutter - Available Commands$(NC)"
	@echo "======================================"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "$(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo "$(YELLOW)Usage:$(NC) make [target]"

# Frontend (Flutter) targets
.PHONY: run-frontend
run-frontend: ## Run Flutter web server (flutter run -d web-server)
	@echo "$(BLUE)Starting Flutter web server...$(NC)"
	flutter run -d web-server

.PHONY: run-frontend-remote
run-frontend-remote: ## Run Flutter pointing to remote backend (BACKEND_URL default uses Environment)
	@echo "$(BLUE)Starting Flutter web server (remote backend)...$(NC)"
	flutter run -d web-server --dart-define=USE_LOCAL_BACKEND=false

.PHONY: run-frontend-local
run-frontend-local: ## Run Flutter pointing to localhost backend (override with BACKEND_URL)
	@echo "$(BLUE)Starting Flutter web server (local backend)...$(NC)"
	flutter run -d web-server --dart-define=USE_LOCAL_BACKEND=true

.PHONY: run-frontend-url
run-frontend-url: ## Run Flutter with custom BACKEND_URL (usage: make run-frontend-url URL=http://host:port)
	@if [ -z "$(URL)" ]; then echo "$(RED)URL is required: make run-frontend-url URL=http://host:port$(NC)"; exit 1; fi
	@echo "$(BLUE)Starting Flutter with BACKEND_URL=$(URL)...$(NC)"
	flutter run -d web-server --dart-define=BACKEND_URL=$(URL)

# Backend (Go) targets
.PHONY: build-backend
build-backend: ## Build the Go backend binary
	@echo "$(BLUE)Building Go backend...$(NC)"
	@cd $(BACKEND_DIR) && GOOS=linux GOARCH=amd64 go build -o bin/server ./cmd/server
	@echo "$(GREEN)✓ Backend built: $(BACKEND_BIN)$(NC)"

.PHONY: run-backend
run-backend: ## Run the Go backend server
	@echo "$(BLUE)Starting Go backend server...$(NC)"
	@cd $(BACKEND_DIR) && go run ./cmd/server

.PHONY: run-backend-port
run-backend-port: ## Run Go backend on specific port (usage: make run-backend-port PORT=8080)
	@if [ -z "$(PORT)" ]; then echo "$(YELLOW)PORT not set, defaulting to 8080$(NC)"; fi
	@cd $(BACKEND_DIR) && HTTP_PORT=$${PORT:-8080} go run ./cmd/server

.PHONY: backend-test
backend-test: ## Run Go backend tests
	@echo "$(BLUE)Running backend tests...$(NC)"
	@cd $(BACKEND_DIR) && go test ./...

# Testing targets
.PHONY: test
test: backend-test ## Run all tests
	@echo "$(BLUE)Running Flutter tests...$(NC)"
	flutter test
	@echo "$(GREEN)✓ All tests completed$(NC)"

# Utility targets
.PHONY: check
check: ## Run code analysis and linting
	@echo "$(BLUE)Running Flutter analyzer...$(NC)"
	flutter analyze
	@echo "$(BLUE)Running Go linting (if golangci-lint is installed)...$(NC)"
	@cd $(BACKEND_DIR) && (command -v golangci-lint >/dev/null 2>&1 && golangci-lint run || echo "$(YELLOW)golangci-lint not installed, skipping$(NC)")

.PHONY: format
format: ## Format code (Flutter and Go)
	@echo "$(BLUE)Formatting Flutter code...$(NC)"
	dart format lib/ test/
	@echo "$(BLUE)Formatting Go code...$(NC)"
	@cd $(BACKEND_DIR) && go fmt ./...
	@echo "$(GREEN)✓ All code formatted$(NC)"

# Installation check
.PHONY: check-tools
check-tools: ## Check if required tools are installed
	@echo "$(BLUE)Checking required tools...$(NC)"
	@echo ""
	@command -v flutter >/dev/null 2>&1 && echo "$(GREEN)✓ Flutter$(NC)" || echo "$(RED)✗ Flutter (required)$(NC)"
	@command -v go >/dev/null 2>&1 && echo "$(GREEN)✓ Go$(NC)" || echo "$(RED)✗ Go (required for backend)$(NC)"
	@command -v docker >/dev/null 2>&1 && echo "$(GREEN)✓ Docker$(NC)" || echo "$(YELLOW)⚠ Docker (optional)$(NC)"
	@command -v air >/dev/null 2>&1 && echo "$(GREEN)✓ Air$(NC)" || echo "$(YELLOW)⚠ Air (optional - for hot reload)$(NC)"
	@command -v golangci-lint >/dev/null 2>&1 && echo "$(GREEN)✓ golangci-lint$(NC)" || echo "$(YELLOW)⚠ golangci-lint (optional - for linting)$(NC)"

# Log Management targets
.PHONY: logs
logs: ## View formatted backend logs (usage: make logs [FILE=logfile])
	@if [ -z "$(FILE)" ]; then \
		echo "$(YELLOW)Usage: make logs FILE=path/to/logfile$(NC)"; \
		echo "$(YELLOW)Or pipe logs: go run backend/cmd/server 2>&1 | make logs-pipe$(NC)"; \
	else \
		$(BACKEND_DIR)/scripts/logs.sh "$(FILE)"; \
	fi

.PHONY: logs-pipe
logs-pipe: ## Format piped logs from stdin (usage: command | make logs-pipe)
	@$(BACKEND_DIR)/scripts/logs.sh

.PHONY: logs-follow
logs-follow: ## Follow and format logs in real-time (usage: make logs-follow FILE=logfile)
	@if [ -z "$(FILE)" ]; then \
		echo "$(RED)FILE is required: make logs-follow FILE=path/to/logfile$(NC)"; \
		exit 1; \
	fi
	@$(BACKEND_DIR)/scripts/logs.sh -f "$(FILE)"

.PHONY: logs-compact
logs-compact: ## View logs in compact mode (usage: make logs-compact FILE=logfile)
	@if [ -z "$(FILE)" ]; then \
		echo "$(RED)FILE is required: make logs-compact FILE=path/to/logfile$(NC)"; \
		exit 1; \
	fi
	@$(BACKEND_DIR)/scripts/logs.sh -c "$(FILE)"

.PHONY: logs-errors
logs-errors: ## View only ERROR level logs (usage: make logs-errors FILE=logfile)
	@if [ -z "$(FILE)" ]; then \
		echo "$(RED)FILE is required: make logs-errors FILE=path/to/logfile$(NC)"; \
		exit 1; \
	fi
	@$(BACKEND_DIR)/scripts/logs.sh -l ERROR "$(FILE)"

.PHONY: logs-game
logs-game: ## Filter logs by game ID (usage: make logs-game FILE=logfile GAME=game_id)
	@if [ -z "$(FILE)" ] || [ -z "$(GAME)" ]; then \
		echo "$(RED)Both FILE and GAME are required: make logs-game FILE=path/to/logfile GAME=game_id$(NC)"; \
		exit 1; \
	fi
	@$(BACKEND_DIR)/scripts/logs.sh --game "$(GAME)" "$(FILE)"

.PHONY: logs-help
logs-help: ## Show help for log viewer
	@$(BACKEND_DIR)/scripts/logs.sh --help

# Quick start
.PHONY: setup
setup: check-tools deps ## Initial project setup - install tools and dependencies
	@echo "$(GREEN)✓ Project setup complete!$(NC)"
	@echo ""
	@echo "Run $(GREEN)make run-dev$(NC) for development instructions"
