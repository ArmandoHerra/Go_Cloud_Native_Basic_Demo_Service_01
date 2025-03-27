# Stage 1: Build stage
FROM golang:1.24.1-alpine3.21 AS builder

# Set the working directory
WORKDIR /app

# Copy go.mod and go.sum from the src directory and download dependencies
COPY src/go.mod ./
RUN go mod download

# Copy the entire source code from the src directory
COPY src/ .

# Build the application
RUN go build -o basic-demo-microservice .

# Stage 2: Final stage
FROM gcr.io/distroless/base
WORKDIR /app

# Copy the compiled binary from the builder stage
COPY --from=builder /app/basic-demo-microservice .

# Copy the .env file from the src directory into the image
COPY src/.env /app/.env

EXPOSE 80
CMD ["./basic-demo-microservice"]
