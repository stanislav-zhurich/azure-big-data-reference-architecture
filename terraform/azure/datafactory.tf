resource "azurerm_data_factory" "data_factory" {
  name                 = substr("data-factory-${local.resource_prefix}", 0, 63)
  location             = azurerm_resource_group.resource_group.location
  resource_group_name  = azurerm_resource_group.resource_group.name
  github_configuration {
    account_name = var.git_account_name
    branch_name = var.git_branch_name
    repository_name = var.git_repository_name
    root_folder = var.git_root_folder
    git_url = var.git_url
  }
  identity {
    type = "SystemAssigned"
  }
  tags = local.tags
}

resource "azurerm_role_assignment" "df_datalake_role_assignement" {
  for_each             = toset(["Contributor", "Storage Blob Data Owner"])
  role_definition_name = each.value

  scope        = azurerm_storage_account.datalake_storage_account.id
  principal_id = azurerm_data_factory.data_factory.identity[0].principal_id
}


resource "azurerm_role_assignment" "df_source_role_assignement" {
  for_each             = toset(["Contributor", "Storage Blob Data Owner"])
  role_definition_name = each.value

  scope        = azurerm_storage_account.source_storage_account.id
  principal_id = azurerm_data_factory.data_factory.identity[0].principal_id
}

resource "azurerm_role_assignment" "df_owner_role_assignement" {
  scope                = azurerm_data_factory.data_factory.id
  role_definition_name = "Owner"
  principal_id         = data.azuread_client_config.current.object_id
}

resource "azurerm_data_factory_linked_service_azure_blob_storage" "patient_blob_data_source_linked_service" {
  name                 = "blobSourceBlobStorageLinkedService"
  data_factory_id      = azurerm_data_factory.data_factory.id
  use_managed_identity = true
  service_endpoint     = "https://${azurerm_storage_account.source_storage_account.name}.blob.core.windows.net"
}


resource "azurerm_data_factory_linked_service_data_lake_storage_gen2" "datalake_linked_service" {
  name                 = "datalakeLinkedService"
  data_factory_id      = azurerm_data_factory.data_factory.id
  url                  = "https://${azurerm_storage_account.datalake_storage_account.name}.dfs.core.windows.net/"
  use_managed_identity = true
}

resource "azurerm_data_factory_linked_service_key_vault" "key_vault_linked_service" {
  name            = "keyVaultLinkedService"
  data_factory_id = azurerm_data_factory.data_factory.id
  key_vault_id    = azurerm_key_vault.key_vault.id
}

resource "azurerm_key_vault_access_policy" "df_keyvault_policy" {
  key_vault_id = azurerm_key_vault.key_vault.id
  tenant_id    = azurerm_data_factory.data_factory.identity[0].tenant_id
  object_id    = azurerm_data_factory.data_factory.identity[0].principal_id

  secret_permissions = [
    "Get", "List", "Set", "Delete", "Recover", "Purge"
  ]
}

resource "azurerm_data_factory_linked_service_azure_databricks" "databricks_cluster_linked_servie" {
  name                       = "databricksClusterLinkedService"
  data_factory_id            = azurerm_data_factory.data_factory.id
  existing_cluster_id        = databricks_cluster.databricks_cluster.cluster_id
  msi_work_space_resource_id = azurerm_databricks_workspace.databricks_workspace.id
  adb_domain                 = "https://${azurerm_databricks_workspace.databricks_workspace.workspace_url}"
}

resource "azurerm_role_assignment" "df_databricks_role_assignement" {
  for_each             = toset(["Contributor", "Storage Blob Data Owner"])
  role_definition_name = each.value

  scope        = azurerm_databricks_workspace.databricks_workspace.id
  principal_id = azurerm_data_factory.data_factory.identity[0].principal_id
}


/* resource "azurerm_data_factory_trigger_blob_event" "blob_trigger" {
  name                = "PatientFileAddedTrigger"
  data_factory_id     = azurerm_data_factory.data_factory.id
  storage_account_id  = azurerm_storage_account.source_storage_account.id
  events              = ["Microsoft.Storage.BlobCreated"]
  ignore_empty_blobs  = true
  activated           = true

  annotations = ["test1", "test2", "test3"]
  description = "example description"

  pipeline {
    name = azurerm_data_factory_pipeline.example.name
    parameters = {
      Env = "Prod"
    }
  }

  additional_properties = {
    foo = "foo1"
    bar = "bar2"
  }
}
 */