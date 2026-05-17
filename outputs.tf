# Storage Account Outputs
output "storage_account_id" {
  description = "The ID of the storage account"
  value       = azurerm_storage_account.terraform_state.id
}

output "storage_account_name" {
  description = "The name of the storage account"
  value       = azurerm_storage_account.terraform_state.name
}

output "storage_account_primary_blob_endpoint" {
  description = "The primary blob endpoint of the storage account"
  value       = azurerm_storage_account.terraform_state.primary_blob_endpoint
}

output "storage_container_name" {
  description = "The name of the blob container"
  value       = azurerm_storage_container.terraform_state.name
}

# Key Vault Outputs
output "key_vault_id" {
  description = "The ID of the Key Vault"
  value       = azurerm_key_vault.management.id
}

output "key_vault_name" {
  description = "The name of the Key Vault"
  value       = azurerm_key_vault.management.name
}

output "key_vault_vault_uri" {
  description = "The URI of the Key Vault"
  value       = azurerm_key_vault.management.vault_uri
}

output "key_vault_tenant_id" {
  description = "The tenant ID associated with the Key Vault"
  value       = azurerm_key_vault.management.tenant_id
}

# Resource Group Outputs
output "resource_group_id" {
  description = "The ID of the resource group"
  value       = azurerm_resource_group.management.id
}

output "resource_group_name" {
  description = "The name of the resource group"
  value       = azurerm_resource_group.management.name
}

output "resource_group_location" {
  description = "The location of the resource group"
  value       = azurerm_resource_group.management.location
}

# Connection Information for Remote State Configuration
output "remote_state_config" {
  description = "Configuration details for remote state setup in other projects"
  value = {
    resource_group_name  = azurerm_resource_group.management.name
    storage_account_name = azurerm_storage_account.terraform_state.name
    container_name       = azurerm_storage_container.terraform_state.name
    key                  = "example/terraform.tfstate"
  }
  sensitive = false
}

# Azure Context Information
output "azure_context" {
  description = "Azure context information"
  value = {
    subscription_id = data.azurerm_client_config.current.subscription_id
    tenant_id       = data.azurerm_client_config.current.tenant_id
    client_id       = data.azurerm_client_config.current.client_id
  }
  sensitive = true
}
