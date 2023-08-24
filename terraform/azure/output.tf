output "databricks_studio_url" {
  value = "https://${azurerm_databricks_workspace.databricks_workspace.workspace_url}"
  description = "Databricks studio web endpoint"
}

output "synapse_studio_url" {
  value = azurerm_synapse_workspace.synapse_workspace.connectivity_endpoints.web
  description = "Synapse studio web endpoint"
}

output "datafactory_studio_url" {
  value = "https://adf.azure.com/en/home"
  description = "Data Factory studio web endpoint"
}
