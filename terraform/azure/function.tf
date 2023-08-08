resource "azurerm_service_plan" "service_plan" {
  name                = "app-service-plan"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  os_type             = "Linux"
  sku_name            = "Y1"
  tags                = local.tags
}

resource "azurerm_linux_function_app" "observation_function" {
  name                = "observation-generator-function-app"
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location

  storage_account_name       = azurerm_storage_account.source_storage_account.name
  storage_account_access_key = azurerm_storage_account.source_storage_account.primary_access_key
  service_plan_id            = azurerm_service_plan.service_plan.id

  site_config {
    application_stack {
      java_version = 17
    }
  }
  app_settings = {
    WEBSITE_RUN_FROM_PACKAGE = azurerm_storage_blob.storage_blob_function.url
    accessPolicy : azurerm_eventhub_authorization_rule.observation_eventhub_auth_rule.primary_connection_string
  }

  connection_string {
    name  = "accessPolicy"
    type  = "EventHub"
    value = azurerm_eventhub_authorization_rule.observation_eventhub_auth_rule.primary_connection_string
  }
  identity {
    type = "SystemAssigned"
  }
  tags = local.tags
}

resource "azurerm_role_assignment" "observation_fn_role_assignement" {
  role_definition_name = "Contributor"
  scope                = azurerm_eventhub.observation_eventhub.id
  principal_id         = azurerm_linux_function_app.observation_function.identity[0].principal_id
}

data "archive_file" "function" {
  type        = "zip"
  source_dir  = var.function_source_local_dir
  output_path = var.function_output_dir
}

resource "azurerm_storage_container" "storage_container_function" {
  name                 = "custom-function-releases"
  storage_account_name = azurerm_storage_account.source_storage_account.name
}

resource "azurerm_role_assignment" "role_assignment_storage" {
  scope                = azurerm_storage_account.source_storage_account.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_linux_function_app.observation_function.identity.0.principal_id
}

resource "azurerm_storage_blob" "storage_blob_function" {
  name                   = "functions-${substr(data.archive_file.function.output_md5, 0, 6)}.zip"
  storage_account_name   = azurerm_storage_account.source_storage_account.name
  storage_container_name = azurerm_storage_container.storage_container_function.name
  type                   = "Block"
  content_md5            = data.archive_file.function.output_md5
  source                 = var.function_output_dir
}
