#!/bin/bash
# Setup Azure OIDC for GitHub Actions to push to ACR
# Usage: ./setup-azure-oidc.sh <github-org/repo> [resource-group]

set -e

ACR_NAME="aksmultiregiondemoacr"
APP_NAME="github-actions-${ACR_NAME}"

# Validate arguments
if [ -z "$1" ]; then
    echo "Usage: ./setup-azure-oidc.sh <github-org/repo> [resource-group]"
    echo "Example: ./setup-azure-oidc.sh myorg/myrepo my-resource-group"
    exit 1
fi

GITHUB_REPO="$1"
RESOURCE_GROUP="${2:-}"

echo "=== Azure OIDC Setup for GitHub Actions ==="
echo "GitHub Repo: $GITHUB_REPO"
echo "ACR Name: $ACR_NAME"
echo ""

# Check if logged into Azure
if ! az account show &>/dev/null; then
    echo "Please login to Azure first: az login"
    exit 1
fi

# Get subscription and tenant IDs
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TENANT_ID=$(az account show --query tenantId -o tsv)

echo "Subscription ID: $SUBSCRIPTION_ID"
echo "Tenant ID: $TENANT_ID"
echo ""

# Find ACR resource group if not provided
if [ -z "$RESOURCE_GROUP" ]; then
    echo "Looking up resource group for ACR '$ACR_NAME'..."
    RESOURCE_GROUP=$(az acr show --name "$ACR_NAME" --query resourceGroup -o tsv 2>/dev/null || true)
    if [ -z "$RESOURCE_GROUP" ]; then
        echo "Error: Could not find ACR '$ACR_NAME'. Please provide resource group as second argument."
        exit 1
    fi
fi
echo "Resource Group: $RESOURCE_GROUP"
echo ""

# Create App Registration
echo "Creating App Registration '$APP_NAME'..."
APP_ID=$(az ad app list --display-name "$APP_NAME" --query "[0].appId" -o tsv)

if [ -z "$APP_ID" ] || [ "$APP_ID" == "null" ]; then
    APP_ID=$(az ad app create --display-name "$APP_NAME" --query appId -o tsv)
    echo "Created App Registration with ID: $APP_ID"
else
    echo "App Registration already exists with ID: $APP_ID"
fi

# Create Service Principal if it doesn't exist
echo "Creating Service Principal..."
SP_ID=$(az ad sp list --filter "appId eq '$APP_ID'" --query "[0].id" -o tsv)

if [ -z "$SP_ID" ] || [ "$SP_ID" == "null" ]; then
    SP_ID=$(az ad sp create --id "$APP_ID" --query id -o tsv)
    echo "Created Service Principal"
else
    echo "Service Principal already exists"
fi

# Add Federated Credential for main branch
echo "Adding Federated Credential for main branch..."
CRED_NAME="github-main-branch"

# Check if credential already exists
EXISTING_CRED=$(az ad app federated-credential list --id "$APP_ID" --query "[?name=='$CRED_NAME'].name" -o tsv)

if [ -z "$EXISTING_CRED" ]; then
    az ad app federated-credential create --id "$APP_ID" --parameters "{
        \"name\": \"$CRED_NAME\",
        \"issuer\": \"https://token.actions.githubusercontent.com\",
        \"subject\": \"repo:${GITHUB_REPO}:ref:refs/heads/main\",
        \"audiences\": [\"api://AzureADTokenExchange\"]
    }"
    echo "Created federated credential for main branch"
else
    echo "Federated credential already exists"
fi

# Add Federated Credential for pull requests
echo "Adding Federated Credential for pull requests..."
PR_CRED_NAME="github-pull-request"

EXISTING_PR_CRED=$(az ad app federated-credential list --id "$APP_ID" --query "[?name=='$PR_CRED_NAME'].name" -o tsv)

if [ -z "$EXISTING_PR_CRED" ]; then
    az ad app federated-credential create --id "$APP_ID" --parameters "{
        \"name\": \"$PR_CRED_NAME\",
        \"issuer\": \"https://token.actions.githubusercontent.com\",
        \"subject\": \"repo:${GITHUB_REPO}:pull_request\",
        \"audiences\": [\"api://AzureADTokenExchange\"]
    }"
    echo "Created federated credential for pull requests"
else
    echo "Federated credential for pull requests already exists"
fi

# Grant AcrPush role
echo "Granting AcrPush role on ACR..."
ACR_ID="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}/providers/Microsoft.ContainerRegistry/registries/${ACR_NAME}"

# Check if role assignment already exists
EXISTING_ROLE=$(az role assignment list --assignee "$APP_ID" --scope "$ACR_ID" --role "AcrPush" --query "[0].id" -o tsv 2>/dev/null || true)

if [ -z "$EXISTING_ROLE" ]; then
    az role assignment create \
        --assignee "$APP_ID" \
        --role "AcrPush" \
        --scope "$ACR_ID"
    echo "Granted AcrPush role"
else
    echo "AcrPush role already assigned"
fi

echo ""
echo "=== Setup Complete ==="
echo ""
echo "Add these secrets to your GitHub repository:"
echo "  Settings -> Secrets and variables -> Actions -> New repository secret"
echo ""
echo "┌─────────────────────────┬──────────────────────────────────────┐"
echo "│ Secret Name             │ Value                                │"
echo "├─────────────────────────┼──────────────────────────────────────┤"
printf "│ %-23s │ %-36s │\n" "AZURE_CLIENT_ID" "$APP_ID"
printf "│ %-23s │ %-36s │\n" "AZURE_TENANT_ID" "$TENANT_ID"
printf "│ %-23s │ %-36s │\n" "AZURE_SUBSCRIPTION_ID" "$SUBSCRIPTION_ID"
echo "└─────────────────────────┴──────────────────────────────────────┘"
echo ""
