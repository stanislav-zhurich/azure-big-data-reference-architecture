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