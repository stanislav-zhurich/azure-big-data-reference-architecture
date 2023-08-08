resource "azurerm_key_vault" "key_vault" {
  name                     = "${local.resource_prefix}-kv"
  location                 = azurerm_resource_group.resource_group.location
  resource_group_name      = azurerm_resource_group.resource_group.name
  tenant_id                = data.azuread_client_config.current.tenant_id
  sku_name                 = "standard"
  purge_protection_enabled = false
  tags = local.tags
} 

resource "azurerm_key_vault_access_policy" "deployer_keyvault_policy" {
   key_vault_id = azurerm_key_vault.key_vault.id
   tenant_id    = data.azuread_client_config.current.tenant_id
   object_id    = data.azuread_client_config.current.object_id
   secret_permissions = [
     "Get", "List", "Set", "Delete", "Recover", "Purge"
   ]
}