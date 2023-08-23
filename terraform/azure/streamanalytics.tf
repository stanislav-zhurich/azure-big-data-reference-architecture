resource "azurerm_stream_analytics_job" "stream_analytics_job" {
  name                                     = substr("streamanalyticsbb-${local.resource_prefix}", 0, 63)
  resource_group_name                      = azurerm_resource_group.resource_group.name
  location                                 = azurerm_resource_group.resource_group.location
  compatibility_level                      = "1.2"
  events_late_arrival_max_delay_in_seconds = 60
  events_out_of_order_max_delay_in_seconds = 50
  events_out_of_order_policy               = "Adjust"
  output_error_policy                      = "Drop"
  streaming_units                          = 1


  identity {
    type = "SystemAssigned"
  }

  transformation_query = <<QUERY
    SELECT *
    INTO [YourOutputAlias]
    FROM [YourInputAlias]
QUERY

  tags = local.tags
}

/* resource "azurerm_stream_analytics_stream_input_eventhub" "stream_input_eventhub" {
  name                      = "eventhub-stream-input"
  stream_analytics_job_name = azurerm_stream_analytics_job.stream_analytics_job.name
  resource_group_name       = azurerm_resource_group.resource_group.name
  eventhub_name             = azurerm_eventhub.target_observation_eventhub.name
  servicebus_namespace      = azurerm_eventhub_namespace.eventhub_namespace.name
  authentication_mode       = "Msi"
  serialization {
    type     = "Json"
    encoding = "UTF8"
  }
} */

resource "azurerm_role_assignment" "stream_analytics_event_hub_role_assignement" {
  for_each             = toset(["Contributor", "Azure Event Hubs Data Owner"])
  role_definition_name = each.value

  scope        = azurerm_eventhub.target_observation_eventhub.id
  principal_id = azurerm_stream_analytics_job.stream_analytics_job.identity[0].principal_id
} 
