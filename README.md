# Go Cloud Native Basic Demo Service

A basic microservice written in Go, designed to run on Kubernetes and demonstrate cloud-native patterns.

## Overview

This service is a simple HTTP server that displays information about the Kubernetes node it's running on, including:
- Application version
- Node name
- AWS region
- Availability zone

The service uses the Kubernetes client-go library to query the cluster API and retrieve node topology information.

## Prerequisites

- Go 1.24.1+
- Docker
- Kubernetes cluster (for deployment)
- AWS account with ECR repository (for CI/CD)

## Project Structure

```
.
├── .github/workflows/ci-cd.yml  # GitHub Actions CI/CD pipeline
├── Dockerfile                    # Multi-stage Docker build
├── Makefile                      # Local development commands
├── ecr-login.sh                  # AWS ECR login helper
└── src/
    ├── go.mod                    # Go module definition
    ├── go.sum                    # Dependency lock file
    └── main.go                   # Application entrypoint
```

## Local Development

### Build and Run

```bash
# Build local Docker image
make build-local

# Build and run on port 8080
make run-local

# Shell into running container
make debug

# Clean Docker resources
make clean
```

### Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `NODE_NAME` | Kubernetes node name (injected via Downward API) | Yes |
| `APP_VERSION` | Application version string | No (defaults to "Unknown") |

## Deployment

The service is designed to run inside a Kubernetes cluster and requires:
- In-cluster configuration (service account with node read permissions)
- `NODE_NAME` environment variable set via Downward API

Example pod spec snippet:
```yaml
env:
  - name: NODE_NAME
    valueFrom:
      fieldRef:
        fieldPath: spec.nodeName
  - name: APP_VERSION
    value: "1.0.0"
```

## CI/CD

The GitHub Actions pipeline (`.github/workflows/ci-cd.yml`):
1. Triggers on push/PR to `main` branch
2. Authenticates to AWS via OIDC role assumption
3. Builds Docker image tagged with commit SHA
4. Runs Trivy security scan for vulnerabilities
5. Pushes to AWS ECR private registry

### Required GitHub Secrets

| Secret | Description |
|--------|-------------|
| `CI_CD_ROLE_ARN` | AWS IAM role ARN for OIDC authentication |
| `AWS_ECR_REGISTRY` | ECR registry URL |

## License

See [LICENSE](LICENSE) file.
