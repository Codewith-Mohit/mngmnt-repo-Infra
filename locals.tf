# Data source for current Azure context
data "azurerm_client_config" "current" {}

# Local values for common configuration
locals {
  common_tags = merge(
    var.additional_tags,
    {
      Environment = var.environment
      Project     = var.project
      ManagedBy   = "Terraform"
      CreatedDate = formatdate("YYYY-MM-DD", timestamp())
    }
  )
}
