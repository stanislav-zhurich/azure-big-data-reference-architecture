data "azuread_client_config" "current" {}

locals {
  resource_prefix = "bigdata${random_string.random_prefix.id}"
  tags = {
    Environment = var.environment
    
  }
}

resource "random_string" "random_prefix" {
  length  = 10
  special = false
  upper   = false
}

resource "time_sleep" "role_assignment_sleep" {
  create_duration = "60s"

  triggers = {
    role_assignment = azurerm_role_assignment.user_datalake_role_assignement["Contributor"].id
  }
}

resource "azurerm_resource_group" "resource_group" {
  name = "${local.resource_prefix}_rg"
  location = var.location_name
}







