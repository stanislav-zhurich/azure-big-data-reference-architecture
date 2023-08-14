resource "azurerm_eventhub_namespace" "eventhub_namespace" {
  name                = "big-data-eventhub-namespace"
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

resource "azurerm_eventhub_authorization_rule" "observation_eventhub_auth_rule" {
  name                = "accessPolicy"
  namespace_name      = azurerm_eventhub_namespace.eventhub_namespace.name
  eventhub_name       = azurerm_eventhub.observation_eventhub.name
  resource_group_name = azurerm_resource_group.resource_group.name
  listen              = true
  send                = true
  manage              = true
}

resource "azurerm_key_vault_secret" "event_hub_connection_string_secret" {
  name         = "eventhub-connection-string"
  value        = azurerm_eventhub_authorization_rule.observation_eventhub_auth_rule.primary_connection_string
  key_vault_id = azurerm_key_vault.key_vault.id
} 