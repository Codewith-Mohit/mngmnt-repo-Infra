# Terraform variable values
# Copy this file to terraform.tfvars and update with your specific values

# Azure subscription ID
subscription_id = "519106f4-cfa7-4c39-a811-2c6688b430cf"

# Resource Group
resource_group_name = "rg-management"
location            = "westeurope"

# Storage Account Configuration
storage_account_name             = "stmgmtstate"  # MUST be unique globally, lowercase only
storage_account_tier             = "Standard"
storage_account_replication_type = "GRS"
storage_container_name           = "tfstate"

# Key Vault Configuration
key_vault_name                        = "kv-management-main"
key_vault_sku                         = "standard"
key_vault_soft_delete_retention_days  = 90
key_vault_purge_protection_enabled    = true

# Service Principal (optional - leave as null if not using)
service_principal_object_id = null

# Tags
environment = "production"
project     = "infrastructure-management"

additional_tags = {
  CostCenter = "IT-Infrastructure"
  Owner      = "Platform-Team"
}
