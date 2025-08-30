# syntax=docker/dockerfile:1

FROM golang:1.22-alpine AS builder
WORKDIR /app
RUN apk add --no-cache git ca-certificates
COPY go.mod ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o server ./cmd/server

FROM gcr.io/distroless/base-debian12:nonroot
WORKDIR /
COPY --from=builder /app/server /server

# Environment variables for configuration
ENV HTTP_PORT=8080
ENV LOG_LEVEL=INFO
ENV LOG_FORMAT=json
ENV LOG_OUTPUT=stdout
ENV CORS_ORIGINS=*

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD ["/server", "--healthcheck"] || exit 1

EXPOSE 8080
USER nonroot:nonroot
ENTRYPOINT ["/server"]

