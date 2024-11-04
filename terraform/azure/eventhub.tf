resource "azurerm_eventhub_namespace" "eventhub_namespace" {
  name                = substr("eventhub-namespace-${local.resource_prefix}", 0, 63)
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  sku                 = "Basic"
  capacity            = 1
  identity {
    type = "SystemAssigned"
  }

  tags = local.tags
}

resource "azurerm_eventhub" "observation_eventhub" {
  name                = "observation-generator-event-hub"
  namespace_name      = azurerm_eventhub_namespace.eventhub_namespace.name
  resource_group_name = azurerm_resource_group.resource_group.name
  partition_count     = 1
  message_retention   = 1
}

resource "azurerm_eventhub" "target_observation_eventhub" {
  name                = "target-event-hub"
  namespace_name      = azurerm_eventhub_namespace.eventhub_namespace.name
  resource_group_name = azurerm_resource_group.resource_group.name
  partition_count     = 1
  message_retention   = 1
}

resource "azurerm_eventhub_authorization_rule" "observation_eventhub_auth_rule" {
  name                = "accessPolicy"
  namespace_name      = azurerm_eventhub_namespace.eventhub_namespace.name
  eventhub_name       = azurerm_eventhub.observation_eventhub.name
  resource_group_name = azurerm_resource_group.resource_group.name
  listen              = true
  send                = true
  manage              = true
}

resource "azurerm_eventhub_authorization_rule" "target_observation_eventhub_auth_rule" {
  name                = "accessPolicy"
  namespace_name      = azurerm_eventhub_namespace.eventhub_namespace.name
  eventhub_name       = azurerm_eventhub.target_observation_eventhub.name
  resource_group_name = azurerm_resource_group.resource_group.name
  listen              = true
  send                = true
  manage              = true
}

resource "azurerm_key_vault_secret" "source_event_hub_connection_string_secret" {
  depends_on = [ azurerm_key_vault_access_policy.deployer_keyvault_policy ]
  name         = "source-eventhub-connection-string"
  value        = azurerm_eventhub_authorization_rule.observation_eventhub_auth_rule.primary_connection_string
  key_vault_id = azurerm_key_vault.key_vault.id
} 

resource "azurerm_key_vault_secret" "target_event_hub_connection_string_secret" {
  depends_on = [ azurerm_key_vault_access_policy.deployer_keyvault_policy ]
  name         = "target-eventhub-connection-string"
  value        = azurerm_eventhub_authorization_rule.target_observation_eventhub_auth_rule.primary_connection_string
  key_vault_id = azurerm_key_vault.key_vault.id
} 