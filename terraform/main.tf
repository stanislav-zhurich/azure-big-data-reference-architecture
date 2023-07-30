data "azuread_client_config" "current" {}

locals {
  resource_prefix = "project-${data.azuread_client_config.current.object_id}"
}

resource "azurerm_resource_group" "resource_group" {
  name = "${local.resource_prefix}_rg"
  location = var.location_name
}

resource "azurerm_storage_account" "datalake_storage_account" {
  name                     = substr(replace("dl${local.resource_prefix}", "-", ""), 0, 24)
  resource_group_name      = azurerm_resource_group.resource_group.name
  location                 = azurerm_resource_group.resource_group.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = "true"
  
}

resource "azurerm_storage_account" "source_storage_account" {
  name                     = substr(replace("src${local.resource_prefix}", "-", ""), 0, 24)
  resource_group_name      = azurerm_resource_group.resource_group.name
  location                 = azurerm_resource_group.resource_group.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = "true"
}

resource "azurerm_storage_container" "source_container" {
  name                  = "patient-data-source"
  storage_account_name  = azurerm_storage_account.source_storage_account.name
  container_access_type = "private"
}
  

resource "time_sleep" "role_assignment_sleep" {
  create_duration = "60s"

  triggers = {
    role_assignment = azurerm_role_assignment.user_datalake_role_assignement["Contributor"].id
  }
}

resource "azurerm_role_assignment" "user_datalake_role_assignement" {  
  for_each = toset(["Contributor", "Storage Blob Data Owner"])
  role_definition_name               = each.value

  scope                = azurerm_storage_account.datalake_storage_account.id   
  principal_id         = data.azuread_client_config.current.object_id  
}  

resource "azurerm_role_assignment" "synapse_datalake_role_assignement" {  
  for_each = toset(["Contributor", "Storage Blob Data Owner"])
  role_definition_name               = each.value

  scope                = azurerm_storage_account.datalake_storage_account.id  
  principal_id         = azurerm_synapse_workspace.synapse_workspace.identity[0].principal_id  
}  
  

resource "azurerm_role_assignment" "synapse_source_role_assignement" {  
  for_each = toset(["Contributor", "Storage Blob Data Owner"])
  role_definition_name               = each.value

  scope                = azurerm_storage_account.source_storage_account.id    
  principal_id         = azurerm_synapse_workspace.synapse_workspace.identity[0].principal_id  
}  
  

resource "azurerm_storage_data_lake_gen2_filesystem" "adls" {
  name               = "datalake"
  storage_account_id = azurerm_storage_account.datalake_storage_account.id
  depends_on = [ time_sleep.role_assignment_sleep ]
}

resource "azurerm_storage_data_lake_gen2_path" "datalake_path" {
  for_each = toset(["bronze", "silver", "gold"])
  path               = each.value
  filesystem_name    = azurerm_storage_data_lake_gen2_filesystem.adls.name
  storage_account_id = azurerm_storage_account.datalake_storage_account.id
  resource           = "directory"

  owner = data.azuread_client_config.current.object_id
  ace {
    id       = azurerm_synapse_workspace.synapse_workspace.identity[0].principal_id
    type     = "user"
    permissions = "rwx"
  }
  ace {
    id       = data.azuread_client_config.current.object_id
    type     = "user"
    permissions = "rwx"
  }
}

resource "azurerm_synapse_workspace" "synapse_workspace" {
  name                                 = substr("${local.resource_prefix}workspace", 0, 49)
  resource_group_name                  = azurerm_resource_group.resource_group.name
  location                             = azurerm_resource_group.resource_group.location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.adls.id
  sql_administrator_login              = "sqladminuser"
  sql_administrator_login_password     = "H@Sh1CoR3!"
  public_network_access_enabled = true

  github_repo {
    account_name = "stanislav-zhurich"
    branch_name = "main"
    repository_name = "azure-big-data-reference-architecture"
    root_folder = "/configuration"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Env = "production"
  }
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

resource "azurerm_synapse_linked_service" "patient_data_source_linked_service" {
  name                 = "blobStorageLinkedService1"
  synapse_workspace_id = azurerm_synapse_workspace.synapse_workspace.id
  type                 = "AzureBlobStorage"
  type_properties_json = <<JSON
{
  "connectionString": "${azurerm_storage_account.source_storage_account.primary_connection_string}"
}
JSON
  depends_on = [
    azurerm_synapse_firewall_rule.allow_all_rule
  ]
}

/* resource "azurerm_key_vault" "key_vault" {
  name                     = "bigdata-project-kv"
  location                 = azurerm_resource_group.resource_group.location
  resource_group_name      = azurerm_resource_group.resource_group.name
  tenant_id                = data.azuread_client_config.current.tenant_id
  sku_name                 = "standard"
  purge_protection_enabled = true
} */

# resource "azurerm_key_vault_access_policy" "deployer_keyvault_policy" {
#   key_vault_id = azurerm_key_vault.key_vault.id
#   tenant_id    = data.azuread_client_config.current.tenant_id
#   object_id    = data.azuread_client_config.current.object_id
#   secret_permissions = [
#     "Get", "List", "Set", "Delete"
#   ]
# }

# resource "azurerm_key_vault_access_policy" "synapse_keyvault_policy" {
#   key_vault_id = azurerm_key_vault.key_vault.id
#   tenant_id    = azurerm_synapse_workspace.synapse_workspace.identity[0].tenant_id
#   object_id    = azurerm_synapse_workspace.synapse_workspace.identity[0].principal_id

#   secret_permissions = [
#     "Get", "List", "Set", "Delete"
#   ]
# }

# resource "azurerm_key_vault_secret" "blob_access_key_secret" {
#   depends_on = [ azurerm_key_vault_access_policy.deployer_keyvault_policy]
#   name         = "blob-storage-access-key"
#   value = azurerm_storage_account.source_storage_account.primary_access_key
#   key_vault_id = azurerm_key_vault.key_vault.id
# }


