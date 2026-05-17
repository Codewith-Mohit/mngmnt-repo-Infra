# Azure Infrastructure Management - Terraform Configuration

## Overview

This repository contains Terraform configuration for deploying and managing core Azure infrastructure with a focus on state management and secrets.

### Components

- **Storage Account**: Centralized Terraform state management for customer/application subscription infrastructure
- **Key Vault**: Secrets and certificates management for service principals responsible for automation, monitoring, and third-party integrations

## Prerequisites

1. **Terraform** >= 1.0 ([Install](https://www.terraform.io/downloads.html))
2. **Azure CLI** ([Install](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli))
3. **Azure Subscription** with appropriate permissions
4. **jq** (optional, for plan summary parsing)

## Quick Start

### 1. Authenticate with Azure

```bash
az login
az account set --subscription <subscription-id>
```

### 2. Clone and Initialize

```bash
cd management-config
cp terraform.tfvars.example terraform.tfvars
```

### 3. Update Configuration

Edit `terraform.tfvars` with your specific values:

```hcl
subscription_id              = "your-subscription-id"
storage_account_name         = "your-unique-storage-name"  # Must be globally unique
key_vault_name              = "your-unique-keyvault-name"   # Must be globally unique
location                    = "East US"
environment                 = "production"
```

### 4. Plan and Apply

```bash
# View what will be created
terraform plan

# Deploy infrastructure
terraform apply
```

Or use the provided script:

```bash
./scripts/init-and-plan.sh
```

## File Structure

```
.
├── main.tf                    # Main configuration (Storage Account, Key Vault, Access Policies)
├── variables.tf               # Variable definitions with validation
├── locals.tf                  # Local values (tags, computed values)
├── outputs.tf                 # Output definitions
├── terraform.tfvars.example   # Example variable values
├── .gitignore                 # Git ignore rules
├── scripts/
│   ├── init-and-plan.sh      # Initialize, validate, and plan
│   └── destroy.sh             # Destroy all resources
└── README.md                  # This file
```

## Configuration Details

### Storage Account

- **Purpose**: Centralized Terraform state repository
- **Access**: Private blob container
- **Replication**: GRS (Geo-Redundant Storage) by default
- **HTTPS Only**: Enforced for security

### Key Vault

- **Purpose**: Secrets and certificate management
- **SKU**: Standard (upgrade to Premium for performance)
- **Soft Delete**: 90 days retention
- **Access Policies**:
  - Current user: Full permissions (for management)
  - Service principal: Read-only access (for automation)

## Usage Examples

### Deploy Infrastructure

```bash
terraform init
terraform plan -out=tfplan
terraform apply tfplan
```

### Output Values

After successful deployment, retrieve outputs:

```bash
terraform output
terraform output -json
terraform output storage_account_name
```

### Configure Remote State for Other Projects

Use the output `remote_state_config` to configure remote state in other Terraform projects:

```hcl
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-management"
    storage_account_name = "stmgmtstate"
    container_name       = "tfstate"
    key                  = "project-name/terraform.tfstate"
  }
}
```

### Add Service Principal Access

To grant a service principal access to Key Vault:

```bash
# Find service principal object ID
az ad sp show --id <client-id> --query id -o tsv

# Update terraform.tfvars
service_principal_object_id = "00000000-0000-0000-0000-000000000000"

# Apply changes
terraform apply
```

### Store Secrets in Key Vault

```bash
az keyvault secret set --vault-name <key-vault-name> \
  --name "app-secret-name" \
  --value "secret-value"
```

## Security Best Practices

1. **State File Protection**: Store `terraform.tfstate` in remote backend, never commit locally
2. **Secrets**: Use Azure Key Vault instead of environment variables
3. **Access Control**: Use managed identities and service principals with minimal permissions
4. **Audit Logging**: Enable diagnostic settings on Key Vault and Storage Account
5. **Encryption**: All data in transit (HTTPS) and at rest (Azure-managed encryption)

## Troubleshooting

### Storage Account Name Conflict

If you get an error about the storage account name already existing globally:
- Storage account names must be globally unique across Azure
- Update `storage_account_name` in `terraform.tfvars` with a different name

### Key Vault Name Conflict

Similar to storage account, Key Vault names must be globally unique:
- Update `key_vault_name` in `terraform.tfvars` with a different name

### Permission Errors

Ensure your Azure account has the following roles:
- `Owner` or `Contributor` on the subscription
- Or specific roles: `Storage Account Contributor`, `Key Vault Administrator`

### Remote State Backend Errors

If you encounter issues with the remote backend:
1. Comment out the `backend` block in `main.tf` temporarily
2. Run `terraform init` to reinitialize with local state
3. Once infrastructure is created, uncomment and reconfigure

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

Or use the provided script:

```bash
./scripts/destroy.sh
```

## Outputs

After applying, retrieve important information:

```bash
# All outputs
terraform output

# Specific outputs
terraform output storage_account_name
terraform output key_vault_vault_uri
terraform output remote_state_config
```

## Next Steps

1. Deploy this infrastructure
2. Create a storage container for another project's state
3. Configure service principals for automation
4. Set up CI/CD pipeline for continuous deployment

## Support

For issues or questions:
1. Check [Terraform Azure Provider Documentation](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)
2. Review [Azure Storage Account Documentation](https://learn.microsoft.com/en-us/azure/storage/)
3. Check [Azure Key Vault Documentation](https://learn.microsoft.com/en-us/azure/key-vault/)

## License

[Add your license here]

## Authors

- Infrastructure Team
