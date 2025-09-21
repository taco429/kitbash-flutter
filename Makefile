# Kitbash Flutter - Development Makefile
# ========================================
# A self-documenting Makefile for the Kitbash Flutter + Go project

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

.PHONY: build-web
build-web: ## Build Flutter for web production
	@echo "$(BLUE)Building Flutter web app...$(NC)"
	flutter build web

.PHONY: flutter-clean
flutter-clean: ## Clean Flutter build cache
	@echo "$(BLUE)Cleaning Flutter build cache...$(NC)"
	flutter clean

.PHONY: flutter-deps
flutter-deps: ## Install/update Flutter dependencies
	@echo "$(BLUE)Installing Flutter dependencies...$(NC)"
	flutter pub get

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

.PHONY: backend-dev
backend-dev: ## Run Go backend with hot reload (requires air)
	@echo "$(BLUE)Starting Go backend with hot reload...$(NC)"
	@cd $(BACKEND_DIR) && air

.PHONY: backend-test
backend-test: ## Run Go backend tests
	@echo "$(BLUE)Running backend tests...$(NC)"
	@cd $(BACKEND_DIR) && go test ./...

.PHONY: backend-tidy
backend-tidy: ## Tidy Go modules
	@echo "$(BLUE)Tidying Go modules...$(NC)"
	@cd $(BACKEND_DIR) && go mod tidy

# Combined targets
.PHONY: run
run: ## Run both frontend and backend (requires separate terminals)
	@echo "$(YELLOW)Starting both services...$(NC)"
	@echo "$(YELLOW)Note: This will run both in the same terminal. Consider using 'make run-dev' instead.$(NC)"
	@make run-backend & make run-frontend

.PHONY: run-dev
run-dev: ## Instructions for running both services in development
	@echo "$(BLUE)Development Setup Instructions:$(NC)"
	@echo "======================================"
	@echo ""
	@echo "Open two terminal windows and run:"
	@echo ""
	@echo "  Terminal 1: $(GREEN)make run-backend$(NC)"
	@echo "  Terminal 2: $(GREEN)make run-frontend$(NC)"
	@echo ""
	@echo "Or use tmux/screen for split terminals"

.PHONY: build
build: build-backend build-web ## Build both backend and frontend

.PHONY: clean
clean: flutter-clean ## Clean all build artifacts
	@echo "$(BLUE)Cleaning backend build artifacts...$(NC)"
	@rm -rf $(BACKEND_DIR)/bin
	@echo "$(GREEN)✓ All build artifacts cleaned$(NC)"

.PHONY: deps
deps: flutter-deps backend-tidy ## Install all dependencies (Flutter and Go)
	@echo "$(GREEN)✓ All dependencies installed$(NC)"

# Docker targets (if using Docker)
.PHONY: docker-build
docker-build: ## Build Docker containers
	@echo "$(BLUE)Building Docker containers...$(NC)"
	docker-compose build

.PHONY: docker-up
docker-up: ## Start Docker containers
	@echo "$(BLUE)Starting Docker containers...$(NC)"
	docker-compose up

.PHONY: docker-down
docker-down: ## Stop Docker containers
	@echo "$(BLUE)Stopping Docker containers...$(NC)"
	docker-compose down

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

# Quick start
.PHONY: setup
setup: check-tools deps ## Initial project setup - install tools and dependencies
	@echo "$(GREEN)✓ Project setup complete!$(NC)"
	@echo ""
	@echo "Run $(GREEN)make run-dev$(NC) for development instructions"
