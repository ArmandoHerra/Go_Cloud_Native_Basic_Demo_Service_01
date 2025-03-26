# Stage 1: Build stage
FROM golang:1.18-alpine AS builder

# Set the working directory
WORKDIR /app

# Copy go.mod and go.sum from the src directory and download dependencies
COPY src/go.mod ./
RUN go mod download

# Copy the entire source code from the src directory
COPY src/ .

# Build the application
RUN go build -o basic-demo-service .

# Stage 2: Final stage
FROM alpine:3.14
WORKDIR /app

# Copy the compiled binary from the builder stage
COPY --from=builder /app/basic-demo-service .

# Copy the .env file from the src directory into the image
COPY src/.env /app/.env

EXPOSE 80
CMD ["./basic-demo-service"]
