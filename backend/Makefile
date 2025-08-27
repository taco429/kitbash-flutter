APP_NAME=kitbash-backend
BIN_DIR=bin

.PHONY: build run test tidy

build:
	GOOS=linux GOARCH=amd64 go build -o $(BIN_DIR)/server ./cmd/server

run:
	go run ./cmd/server

test:
	go test ./...

tidy:
	go mod tidy

