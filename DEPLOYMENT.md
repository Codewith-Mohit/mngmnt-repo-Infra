# Deployment Workflow Guide

This document outlines the step-by-step process for deploying and managing the Azure infrastructure.

## Table of Contents

1. [Prerequisites Setup](#prerequisites-setup)
2. [Initial Deployment](#initial-deployment)
3. [Managing Service Principals](#managing-service-principals)
4. [Key Vault Operations](#key-vault-operations)
5. [Storage Account for Remote State](#storage-account-for-remote-state)
6. [Monitoring and Maintenance](#monitoring-and-maintenance)

## Prerequisites Setup

### 1. Install Required Tools

```bash
# macOS
brew install terraform azure-cli jq

# Linux (Ubuntu/Debian)
sudo apt-get install terraform azure-cli jq

# Windows (with Chocolatey)
choco install terraform azure-cli jq
```

### 2. Verify Installations

```bash
terraform version
az --version
jq --version
```

### 3. Azure Subscription Setup

```bash
# Login to Azure
az login

# Set default subscription
az account set --subscription <SUBSCRIPTION_ID>

# Verify you're using the correct subscription
az account show --query "{Name:name, ID:id}" -o table
```

### 4. Verify Permissions

Your Azure account needs these roles:

```bash
# Check your current roles
az role assignment list --assignee $(az account show --query user.name -o tsv) --output table

# Required roles:
# - Owner
# - OR Contributor + Role-Based Access Control Administrator
```

## Initial Deployment

### Step 1: Clone and Configure

```bash
# Navigate to the project directory
cd management-config

# Create your configuration file
cp terraform.tfvars.example terraform.tfvars

# Edit with your values
nano terraform.tfvars  # or your preferred editor
```

### Step 2: Configure terraform.tfvars

```hcl
subscription_id              = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

# Storage Account (must be globally unique)
storage_account_name         = "stmgmtstatedev01"  # lowercase only, 3-24 chars
storage_account_tier         = "Standard"
storage_account_replication_type = "GRS"

# Key Vault (must be globally unique)
key_vault_name              = "kv-management-prod-01"
key_vault_sku               = "standard"
key_vault_soft_delete_retention_days = 90
key_vault_purge_protection_enabled = true

# Resource configuration
resource_group_name         = "rg-management"
location                    = "East US"
environment                 = "production"
project                     = "infrastructure-management"

# Optional: Service Principal for automation
service_principal_object_id = null

# Tags for cost tracking
additional_tags = {
  CostCenter = "IT-Infrastructure"
  Owner      = "Platform-Team"
  Department = "DevOps"
}
```

### Step 3: Initialize Terraform

```bash
# Initialize Terraform working directory
terraform init

# Validate the configuration
terraform validate

# Format check
terraform fmt -check -recursive .
```

### Step 4: Review the Plan

```bash
# Create a plan
terraform plan -out=tfplan

# Review the plan
terraform show tfplan

# Or view in JSON format
terraform show -json tfplan | jq '.'
```

### Step 5: Apply Configuration

```bash
# Apply the plan
terraform apply tfplan

# Or directly apply (will prompt for confirmation)
terraform apply

# View all outputs
terraform output
```

### Step 6: Retrieve and Save Outputs

```bash
# Export outputs to a file for reference
terraform output -json > infrastructure_outputs.json

# Save critical information
terraform output storage_account_name > sa_name.txt
terraform output key_vault_vault_uri > kv_uri.txt
terraform output remote_state_config > remote_state_config.json
```

## Managing Service Principals

### Create Service Principal for Automation

```bash
# Create service principal
az ad sp create-for-rbac \
  --name "sp-automation-platform" \
  --role Contributor \
  --scopes /subscriptions/<SUBSCRIPTION_ID>

# Save the output (you'll need: appId, password, tenant)
```

### Grant Service Principal Key Vault Access

```bash
# Get service principal object ID
SP_OBJECT_ID=$(az ad sp show --id <CLIENT_ID> --query id -o tsv)

# Update terraform.tfvars
service_principal_object_id = "<SP_OBJECT_ID>"

# Apply changes
terraform apply -auto-approve
```

### Verify Service Principal Access

```bash
# Test access to Key Vault
az keyvault secret list \
  --vault-name <KEY_VAULT_NAME> \
  --subscription <SUBSCRIPTION_ID>
```

## Key Vault Operations

### Store Secrets

```bash
# Store a secret
az keyvault secret set \
  --vault-name <KEY_VAULT_NAME> \
  --name "database-password" \
  --value "secure_password_here"

# Store multiple secrets from file
while IFS='=' read -r key value; do
  az keyvault secret set \
    --vault-name <KEY_VAULT_NAME> \
    --name "$key" \
    --value "$value"
done < secrets.env
```

### Retrieve Secrets

```bash
# Get a secret
az keyvault secret show \
  --vault-name <KEY_VAULT_NAME> \
  --name "database-password" \
  --query value -o tsv

# List all secrets
az keyvault secret list \
  --vault-name <KEY_VAULT_NAME> \
  --query "[].name" -o table
```

### Rotate Secrets

```bash
# Update a secret (same as creating, but it updates if exists)
az keyvault secret set \
  --vault-name <KEY_VAULT_NAME> \
  --name "api-key" \
  --value "new_key_value"
```

### Enable Diagnostic Logging

```bash
# Create storage account for logs
STORAGE_ID=$(az storage account show \
  --name <STORAGE_ACCOUNT_NAME> \
  --resource-group <RESOURCE_GROUP> \
  --query id -o tsv)

# Enable diagnostic settings
az monitor diagnostic-settings create \
  --resource-group <RESOURCE_GROUP> \
  --name keyvault-diagnostics \
  --resource /subscriptions/<SUBSCRIPTION_ID>/resourcegroups/<RESOURCE_GROUP>/providers/Microsoft.KeyVault/vaults/<KEY_VAULT_NAME> \
  --storage-account $STORAGE_ID \
  --logs '[{"category":"AuditEvent","enabled":true}]'
```

## Storage Account for Remote State

### Enable Remote State for Other Projects

Once infrastructure is deployed, other Terraform projects can use this storage account for state:

```hcl
# In your other Terraform projects, configure the backend:

terraform {
  backend "azurerm" {
    resource_group_name  = "rg-management"
    storage_account_name = "stmgmtstatedev01"
    container_name       = "tfstate"
    key                  = "project-name/environment/terraform.tfstate"
  }
}
```

### Create Additional Containers

```bash
# Create a new container for a project
az storage container create \
  --name "tfstate-customer-app" \
  --account-name <STORAGE_ACCOUNT_NAME> \
  --account-key <STORAGE_KEY>

# Or using Terraform:
resource "azurerm_storage_container" "project_state" {
  name                  = "tfstate-project-xyz"
  storage_account_name  = azurerm_storage_account.terraform_state.name
  container_access_type = "private"
}
```

### Configure Storage Account Firewall (Security Best Practice)

```bash
# Get your IP address
MY_IP=$(curl -s https://api.ipify.org)

# Update storage account to allow only your IP
az storage account network-rule add \
  --account-name <STORAGE_ACCOUNT_NAME> \
  --ip-address $MY_IP

# Default action: deny
az storage account update \
  --name <STORAGE_ACCOUNT_NAME> \
  --resource-group <RESOURCE_GROUP> \
  --default-action Deny
```

## Monitoring and Maintenance

### Regular Checks

```bash
# Check Key Vault secrets that are expiring
az keyvault secret list \
  --vault-name <KEY_VAULT_NAME> \
  --query "[].{name:name, expires:attributes.expires}" -o table

# Monitor storage account usage
az storage account show-usage \
  --name <STORAGE_ACCOUNT_NAME> \
  --resource-group <RESOURCE_GROUP>

# Check resource group size and quotas
az group show \
  --name <RESOURCE_GROUP> \
  --query "{Name:name, Location:location}" -o table
```

### Backup and Recovery

```bash
# Backup Key Vault (backup all secrets)
for secret in $(az keyvault secret list --vault-name <KEY_VAULT_NAME> --query "[].name" -o tsv); do
  az keyvault secret backup \
    --vault-name <KEY_VAULT_NAME> \
    --name "$secret"
done

# Enable Azure Backup for storage accounts if needed
# (Requires backup vault setup - beyond scope of this doc)
```

### Update Management

```bash
# Check for Terraform provider updates
terraform init -upgrade

# Update variables and apply changes
terraform plan
terraform apply
```

### Scaling Considerations

```bash
# To upgrade Key Vault from Standard to Premium:
key_vault_sku = "premium"

# To change storage replication:
storage_account_replication_type = "RAGRS"  # Read-Access Geo-Redundant

terraform plan
terraform apply
```

## Troubleshooting

### Common Issues

**Issue**: "Storage account already exists"
```bash
# Solution: Update storage_account_name to be globally unique
# Example: Add timestamp or environment identifier
storage_account_name = "stmgmt${date +%s}prod"
```

**Issue**: "Key Vault name already taken"
```bash
# Solution: Key Vault names must be unique globally
# Try: kv-mgmt-${random_suffix}-${environment}
```

**Issue**: "Insufficient permissions"
```bash
# Solution: Request Role-Based Access Control (RBAC) changes
# Contact subscription admin to grant: Contributor or Owner role
```

**Issue**: "Remote state backend initialization fails"
```bash
# Solution: Re-initialize with local backend first
# Remove backend block from main.tf temporarily
terraform init
# After infrastructure is created, re-add backend and reinitialize
terraform init -migrate-state
```

## Next Steps

1. Document all created resource IDs and names
2. Set up Azure Policy for governance
3. Configure Azure Monitor for alerting
4. Implement automated backups
5. Plan for disaster recovery procedures

---

For additional help, refer to:
- [README.md](./README.md) - General documentation
- [Terraform Azure Provider Docs](https://registry.terraform.io/providers/hashicorp/azurerm/latest)
- [Azure CLI Reference](https://learn.microsoft.com/en-us/cli/azure/)
