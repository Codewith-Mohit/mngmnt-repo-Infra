# Azure Subscription and Authentication
variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
  sensitive   = true
}

# Resource Group Configuration
variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "rg-management"
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

# Storage Account Configuration
variable "storage_account_name" {
  description = "Name of the storage account for Terraform state (must be globally unique, lowercase, 3-24 chars)"
  type        = string
  validation {
    condition     = length(var.storage_account_name) >= 3 && length(var.storage_account_name) <= 24 && can(regex("^[a-z0-9]+$", var.storage_account_name))
    error_message = "Storage account name must be 3-24 characters, lowercase letters and numbers only."
  }
}

variable "storage_account_tier" {
  description = "Storage account tier (Standard or Premium)"
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Standard", "Premium"], var.storage_account_tier)
    error_message = "Storage account tier must be either Standard or Premium."
  }
}

variable "storage_account_replication_type" {
  description = "Storage account replication type"
  type        = string
  default     = "GRS"
  validation {
    condition     = contains(["LRS", "GRS", "RAGRS", "ZRS", "GZRS", "RAGZRS"], var.storage_account_replication_type)
    error_message = "Invalid storage account replication type."
  }
}

variable "storage_container_name" {
  description = "Name of the blob container for Terraform state"
  type        = string
  default     = "tfstate"
}

# Key Vault Configuration
variable "key_vault_name" {
  description = "Name of the Key Vault (must be 3-24 alphanumeric characters, globally unique)"
  type        = string
  #validation {
  #  condition     = length(var.key_vault_name) >= 3 && length(var.key_vault_name) <= 24 && can(regex("^[a-zA-Z0-9-]+$", var.key_vault_name))
  #  error_message = "Key Vault name must be 3-24 characters, alphanumeric and hyphens only."
  #}
}

variable "key_vault_sku" {
  description = "SKU of the Key Vault"
  type        = string
  default     = "standard"
  validation {
    condition     = contains(["standard", "premium"], var.key_vault_sku)
    error_message = "Key Vault SKU must be either standard or premium."
  }
}

variable "key_vault_soft_delete_retention_days" {
  description = "Number of days to retain soft-deleted Key Vault"
  type        = number
  default     = 90
  validation {
    condition     = var.key_vault_soft_delete_retention_days >= 7 && var.key_vault_soft_delete_retention_days <= 90
    error_message = "Soft delete retention days must be between 7 and 90."
  }
}

variable "key_vault_purge_protection_enabled" {
  description = "Enable purge protection for Key Vault"
  type        = bool
  default     = true
}

# Service Principal Configuration
variable "service_principal_object_id" {
  description = "Object ID of the service principal for automation (optional)"
  type        = string
  default     = null
  sensitive   = true
}

# Tags
variable "environment" {
  description = "Environment name"
  type        = string
  default     = "production"
}

variable "project" {
  description = "Project name"
  type        = string
  default     = "infrastructure-management"
}

variable "additional_tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}
