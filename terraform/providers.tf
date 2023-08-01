provider "azurerm" {
  features {

  }
}

provider "databricks" {
  azure_workspace_resource_id = azurerm_databricks_workspace.databricks_workspace.id
  host = azurerm_databricks_workspace.databricks_workspace.workspace_url
  #azure_use_msi = true
  #auth_type  = "azure-cli"
}

/* provider "azuread" {
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
} */
