resource "azurerm_storage_account" "source_storage_account" {
  name                     = substr("source${local.resource_prefix}", 0, 24)
  resource_group_name      = azurerm_resource_group.resource_group.name
  location                 = azurerm_resource_group.resource_group.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = "true"
  tags = local.tags
}

resource "azurerm_storage_container" "source_container" {
  name                  = "patient-data-source"
  storage_account_name  = azurerm_storage_account.source_storage_account.name
  container_access_type = "private"
}
  

resource "azurerm_key_vault_secret" "blob_connection_string_secret" {
   depends_on = [ azurerm_key_vault_access_policy.deployer_keyvault_policy]
   name         = "blob-storage-access-key"
   value = azurerm_storage_account.source_storage_account.primary_connection_string
   key_vault_id = azurerm_key_vault.key_vault.id
}

resource "azurerm_key_vault_secret" "blob_connection_account_name" {
   depends_on = [ azurerm_key_vault_access_policy.deployer_keyvault_policy]
   name         = "blob-storage-account-name"
   value = azurerm_storage_account.source_storage_account.name
   key_vault_id = azurerm_key_vault.key_vault.id
}