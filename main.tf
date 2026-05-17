terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }

  # Uncomment and configure when ready to use remote state
  # backend "azurerm" {
  #   resource_group_name  = "rg-terraform-state"
  #   storage_account_name = "stterraformstate"
  #   container_name       = "tfstate"
  #   key                  = "management/terraform.tfstate"
  # }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = true
    }
  }

  subscription_id = var.subscription_id
}

# Resource Group
resource "azurerm_resource_group" "management" {
  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}

# Storage Account for Terraform State Management
resource "azurerm_storage_account" "terraform_state" {
  name                       = var.storage_account_name
  resource_group_name        = azurerm_resource_group.management.name
  location                   = azurerm_resource_group.management.location
  account_tier               = var.storage_account_tier
  account_replication_type   = var.storage_account_replication_type
  https_traffic_only_enabled = true

  tags = merge(
    local.common_tags,
    {
      Purpose = "Terraform State Management"
    }
  )
}

# Storage Account Blob Container
resource "azurerm_storage_container" "terraform_state" {
  name                  = var.storage_container_name
  storage_account_name  = azurerm_storage_account.terraform_state.name
  container_access_type = "private"
}

# Key Vault for Secrets Management
resource "azurerm_key_vault" "management" {
  name                       = var.key_vault_name
  location                   = azurerm_resource_group.management.location
  resource_group_name        = azurerm_resource_group.management.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = var.key_vault_sku
  soft_delete_retention_days = var.key_vault_soft_delete_retention_days
  purge_protection_enabled   = var.key_vault_purge_protection_enabled

  tags = merge(
    local.common_tags,
    {
      Purpose = "Secret Management for Service Principals"
    }
  )
}

# Access Policy for Current User/Service Principal
resource "azurerm_key_vault_access_policy" "current_user" {
  key_vault_id = azurerm_key_vault.management.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = [
    "Backup",
    "Delete",
    "Get",
    "List",
    "Purge",
    "Recover",
    "Restore",
    "Set"
  ]

  certificate_permissions = [
    "Backup",
    "Create",
    "Delete",
    "Get",
    "List",
    "Purge",
    "Recover",
    "Restore",
    "Update"
  ]

  key_permissions = [
    "Backup",
    "Create",
    "Delete",
    "Get",
    "Import",
    "List",
    "Purge",
    "Recover",
    "Restore",
    "Sign",
    "UnwrapKey",
    "Update",
    "Verify",
    "WrapKey"
  ]
}

# Access Policy for Service Principal (Automation)
# This should be configured per service principal as needed
resource "azurerm_key_vault_access_policy" "service_principal" {
  count        = var.service_principal_object_id != null ? 1 : 0
  key_vault_id = azurerm_key_vault.management.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = var.service_principal_object_id

  secret_permissions = [
    "Get",
    "List"
  ]

  certificate_permissions = [
    "Get",
    "List"
  ]

  key_permissions = [
    "Get",
    "List"
  ]
}
