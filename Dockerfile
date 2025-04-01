# Stage 1: Build stage
FROM golang:1.24.1-alpine3.21 AS builder

# Ensure the binary is statically compiled
ENV CGO_ENABLED=0

# Set the working directory
WORKDIR /app

# Copy go.mod and go.sum from the src directory and download dependencies
COPY src/go.mod src/go.sum ./
RUN go mod download

# Copy the entire source code from the src directory
COPY src/ .

# Build the application (statically linked)
RUN go build -o basic-demo-microservice .

# Ensure Executable Permissions Are Preserved
RUN chmod +x basic-demo-microservice

# Stage 2: Final stage
FROM golang:1.24.1-alpine3.21
WORKDIR /app

# Copy the compiled binary from the builder stage
COPY --from=builder /app/basic-demo-microservice .

# Copy the .env file from the src directory into the image
COPY src/.env /app/.env

EXPOSE 80
CMD ["/app/basic-demo-microservice"]