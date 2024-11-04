resource "azurerm_storage_account" "datalake_storage_account" {
  name                     = substr("datalake${local.resource_prefix}", 0, 24)
  resource_group_name      = azurerm_resource_group.resource_group.name
  location                 = azurerm_resource_group.resource_group.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = "true"
  tags                     = local.tags
}

resource "azurerm_role_assignment" "user_datalake_role_assignement" {
  for_each             = toset(["Contributor", "Storage Blob Data Owner"])
  role_definition_name = each.value

  scope        = azurerm_storage_account.datalake_storage_account.id
  principal_id = data.azuread_client_config.current.object_id
}


resource "azurerm_storage_data_lake_gen2_filesystem" "adls" {
  name = "datalake"

  ace {
    id          = data.azuread_client_config.current.object_id
    type        = "user"
    permissions = "rwx"
  }
 
  storage_account_id = azurerm_storage_account.datalake_storage_account.id
  depends_on         = [time_sleep.role_assignment_sleep]
}

resource "azurerm_storage_data_lake_gen2_path" "datalake_path" {
  for_each           = toset(["bronze", "silver", "gold"])
  path               = each.value
  filesystem_name    = azurerm_storage_data_lake_gen2_filesystem.adls.name
  storage_account_id = azurerm_storage_account.datalake_storage_account.id
  resource           = "directory"

  owner = data.azuread_client_config.current.object_id
  ace {
    id          = azurerm_data_factory.data_factory.identity[0].principal_id
    type        = "user"
    permissions = "rwx"
  }
  ace {
    id          = data.azuread_client_config.current.object_id
    type        = "user"
    permissions = "rwx"
  }
  ace {
    id          = azuread_service_principal.aad_service_sp.client_id
    type        = "user"
    permissions = "rwx"
  }
   ace {
    id          = azurerm_synapse_workspace.synapse_workspace.identity[0].principal_id
    type        = "user"
    permissions = "rwx"
  }
}

resource "azurerm_key_vault_secret" "datalake-access-key-secret" {
  depends_on   = [azurerm_key_vault_access_policy.deployer_keyvault_policy]
  name         = "datalake-access-key"
  value        = azurerm_storage_account.datalake_storage_account.primary_access_key
  key_vault_id = azurerm_key_vault.key_vault.id
} 
