resource "azurerm_synapse_workspace" "synapse_workspace" {
  name                                 = substr("synapse-workspace-${local.resource_prefix}", 0, 63)
  resource_group_name                  = azurerm_resource_group.resource_group.name
  location                             = azurerm_resource_group.resource_group.location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.adls.id
  sql_administrator_login              = "sqladminuser"
  sql_administrator_login_password     = "H@Sh1CoR3!"
  public_network_access_enabled = true

/*   github_repo {
    account_name = var.git_account_name
    branch_name = var.git_branch_name
    repository_name = var.git_repository_name
    root_folder = var.git_root_synapse_folder
    git_url = var.git_url
  } */

  identity {
    type = "SystemAssigned"
  }

  tags = local.tags
}

resource "azurerm_role_assignment" "synapse_workspace_owner_role_assignement" {
  scope                = azurerm_synapse_workspace.synapse_workspace.id
  role_definition_name = "Owner"
  principal_id         = data.azuread_client_config.current.object_id
}

resource "azurerm_synapse_firewall_rule" "allow_all_rule" {
  name                 = "AllowAll"
  synapse_workspace_id = azurerm_synapse_workspace.synapse_workspace.id
  start_ip_address     = "0.0.0.0"
  end_ip_address       = "255.255.255.255"
}

resource "azurerm_role_assignment" "synapse_datalake_role_assignement" {  
  for_each = toset(["Contributor", "Storage Blob Data Owner"])
  role_definition_name               = each.value

  scope                = azurerm_storage_account.datalake_storage_account.id  
  principal_id         = azurerm_synapse_workspace.synapse_workspace.identity[0].principal_id  
} 
