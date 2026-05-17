# Quick Reference Guide

## Project Overview

**Azure Infrastructure Management via Terraform**

A production-ready Terraform configuration for deploying Azure infrastructure with two core components:
- **Azure Storage Account**: For centralized Terraform state management
- **Azure Key Vault**: For secrets and certificates management

## Quick Commands

### Setup & Deployment

```bash
# Copy example configuration
cp terraform.tfvars.example terraform.tfvars

# Edit configuration with your values
vim terraform.tfvars

# Initialize, validate, and plan
make setup
make plan

# Deploy infrastructure
make apply

# View outputs
make output
```

### Using Make Commands

```bash
make help              # Show all available commands
make init              # Initialize Terraform
make validate          # Validate configuration
make plan              # Create deployment plan
make apply             # Apply changes
make destroy           # Destroy all resources
make clean             # Clean local files
make output            # Display outputs
make lint              # Run linting checks
```

### Manual Terraform Commands

```bash
# Initialize
terraform init

# Plan
terraform plan -out=tfplan

# Apply
terraform apply tfplan

# Destroy
terraform destroy

# Output
terraform output -json
```

## Configuration File (terraform.tfvars)

Key required values:

```hcl
subscription_id              = "your-subscription-id"
storage_account_name         = "unique-storage-name"  # globally unique
key_vault_name              = "unique-keyvault-name"   # globally unique
location                    = "East US"
environment                 = "production"
```

## File Structure

```
├── main.tf                    # Main resource definitions
├── variables.tf               # Input variable definitions
├── locals.tf                  # Local value definitions
├── outputs.tf                 # Output value definitions
├── terraform.tfvars.example   # Example configuration
├── Makefile                   # Convenient make commands
├── README.md                  # Full documentation
├── DEPLOYMENT.md              # Step-by-step deployment guide
├── .gitignore                 # Git ignore rules
└── scripts/
    ├── init-and-plan.sh       # Initialize and plan script
    └── destroy.sh             # Destroy resources script
```

## Key Outputs

After deployment, retrieve:

```bash
# Get all outputs
terraform output -json

# Specific outputs
terraform output storage_account_name
terraform output key_vault_vault_uri
terraform output remote_state_config
```

Use `remote_state_config` in other projects for remote state backend.

## Azure CLI Commands

```bash
# Login to Azure
az login

# Set subscription
az account set --subscription <SUBSCRIPTION_ID>

# View current account
az account show

# Create service principal for automation
az ad sp create-for-rbac --name "sp-automation" --role Contributor

# Store secret in Key Vault
az keyvault secret set --vault-name <KEY_VAULT> --name "<SECRET_NAME>" --value "<SECRET_VALUE>"

# Retrieve secret
az keyvault secret show --vault-name <KEY_VAULT> --name "<SECRET_NAME>"
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Storage account already exists | Use globally unique name in terraform.tfvars |
| Key Vault name taken | Try different key vault name |
| Permission denied | Ensure you have Contributor role on subscription |
| Remote backend fails | Comment out backend block, init locally first |

## Security Best Practices

✅ DO:
- Store sensitive values in terraform.tfvars (which is gitignored)
- Use Azure Key Vault for secrets
- Enable soft delete on Key Vault
- Use service principals with minimal permissions
- Enable diagnostic logging

❌ DON'T:
- Commit terraform.tfstate files to git
- Store secrets in terraform.tf
- Use hardcoded credentials
- Grant unnecessary permissions to service principals

## Next Steps

1. **Deploy this infrastructure** using `make apply`
2. **Store secrets** in Key Vault with `az keyvault secret set`
3. **Configure service principals** for automation
4. **Set up remote state** for other projects using `remote_state_config` output
5. **Enable monitoring** with Azure Monitor diagnostic settings

## Documentation

- **README.md**: Full documentation and examples
- **DEPLOYMENT.md**: Step-by-step deployment workflow
- **This file**: Quick reference

## Useful Links

- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest)
- [Azure Storage Account Docs](https://learn.microsoft.com/en-us/azure/storage/)
- [Azure Key Vault Docs](https://learn.microsoft.com/en-us/azure/key-vault/)
- [Azure CLI Docs](https://learn.microsoft.com/en-us/cli/azure/)

## Support

For detailed information, refer to README.md or DEPLOYMENT.md.
