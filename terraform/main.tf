data "azuread_client_config" "current" {}

locals {
  resource_prefix = "bigdata${random_string.random_prefix.id}"
}

resource "random_string" "random_prefix" {
  length  = 10
  special = false
  upper   = false
}

resource "time_sleep" "role_assignment_sleep" {
  create_duration = "60s"

  triggers = {
    role_assignment = azurerm_role_assignment.user_datalake_role_assignement["Contributor"].id
  }
}

resource "azurerm_resource_group" "resource_group" {
  name = "${local.resource_prefix}_rg"
  location = var.location_name
}

resource "azurerm_storage_account" "datalake_storage_account" {
  name                     = substr("datalake${local.resource_prefix}", 0, 24)
  resource_group_name      = azurerm_resource_group.resource_group.name
  location                 = azurerm_resource_group.resource_group.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = "true"
  
}

resource "azurerm_storage_account" "source_storage_account" {
  name                     = substr("source${local.resource_prefix}", 0, 24)
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
  

resource "azurerm_data_factory" "data_factory" {
  name                = substr("data-factory-${local.resource_prefix}", 0, 63)
  location            = azurerm_resource_group.resource_group.location
  resource_group_name = azurerm_resource_group.resource_group.name
  github_configuration {
    account_name = "stanislav-zhurich"
    branch_name = "main"
    repository_name = "azure-big-data-reference-architecture"
    root_folder = "/datafactory"
    git_url = "https://github.com"
  }
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "user_datalake_role_assignement" {  
  for_each = toset(["Contributor", "Storage Blob Data Owner"])
  role_definition_name               = each.value

  scope                = azurerm_storage_account.datalake_storage_account.id   
  principal_id         = data.azuread_client_config.current.object_id  
}  

resource "azurerm_role_assignment" "df_datalake_role_assignement" {  
  for_each = toset(["Contributor", "Storage Blob Data Owner"])
  role_definition_name               = each.value

  scope                = azurerm_storage_account.datalake_storage_account.id  
  principal_id         = azurerm_data_factory.data_factory.identity[0].principal_id  
}  
  

resource "azurerm_role_assignment" "df_source_role_assignement" {  
  for_each = toset(["Contributor", "Storage Blob Data Owner"])
  role_definition_name               = each.value

  scope                = azurerm_storage_account.source_storage_account.id    
  principal_id         = azurerm_data_factory.data_factory.identity[0].principal_id  
}  
  

resource "azurerm_storage_data_lake_gen2_filesystem" "adls" {
  name               = "datalake"
  ace {
    id       = data.azuread_client_config.current.object_id
    type     = "user"
    permissions = "rwx"
  }
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
    id       = azurerm_data_factory.data_factory.identity[0].principal_id
    type     = "user"
    permissions = "rwx"
  }
  ace {
    id       = data.azuread_client_config.current.object_id
    type     = "user"
    permissions = "rwx"
  }
  ace {
    id       = azuread_service_principal.aad_service_sp.application_id
    type     = "user"
    permissions = "rwx"
  }
}


resource "azurerm_role_assignment" "df_owner_role_assignement" {
  scope                = azurerm_data_factory.data_factory.id
  role_definition_name = "Owner"
  principal_id         = data.azuread_client_config.current.object_id
}

resource "azurerm_data_factory_linked_service_azure_blob_storage" "patient_blob_data_source_linked_service" {
  name            = "blobSourceBlobStorageLinkedService"
  data_factory_id = azurerm_data_factory.data_factory.id
  use_managed_identity = true
  service_endpoint = "https://${azurerm_storage_account.source_storage_account.name}.blob.core.windows.net"
}


resource "azurerm_data_factory_linked_service_data_lake_storage_gen2" "datalake_linked_service" {
  name                  = "datalakeLinkedService"
  data_factory_id       = azurerm_data_factory.data_factory.id
  url                   = "https://${azurerm_storage_account.datalake_storage_account.name}.dfs.core.windows.net/"
  use_managed_identity = true
}

resource "azurerm_data_factory_linked_service_key_vault" "key_vault_linked_service" {
  name            = "keyVaultLinkedService"
  data_factory_id = azurerm_data_factory.data_factory.id
  key_vault_id    = azurerm_key_vault.key_vault.id
}



resource "azurerm_key_vault" "key_vault" {
  name                     = "${local.resource_prefix}-kv"
  location                 = azurerm_resource_group.resource_group.location
  resource_group_name      = azurerm_resource_group.resource_group.name
  tenant_id                = data.azuread_client_config.current.tenant_id
  sku_name                 = "standard"
  purge_protection_enabled = false
} 

resource "azurerm_key_vault_access_policy" "deployer_keyvault_policy" {
   key_vault_id = azurerm_key_vault.key_vault.id
   tenant_id    = data.azuread_client_config.current.tenant_id
   object_id    = data.azuread_client_config.current.object_id
   secret_permissions = [
     "Get", "List", "Set", "Delete", "Recover", "Purge"
   ]
}
resource "azurerm_key_vault_access_policy" "df_keyvault_policy" {
   key_vault_id = azurerm_key_vault.key_vault.id
   tenant_id    = azurerm_data_factory.data_factory.identity[0].tenant_id
   object_id    = azurerm_data_factory.data_factory.identity[0].principal_id

   secret_permissions = [
     "Get", "List", "Set", "Delete", "Recover", "Purge"
   ]
 }

 resource "azurerm_key_vault_access_policy" "adb_keyvault_policy" {
   key_vault_id = azurerm_key_vault.key_vault.id
   tenant_id    = data.azuread_client_config.current.tenant_id
   object_id    = azuread_service_principal.aad_service_sp.object_id

   secret_permissions = [
     "Get", "List", "Set", "Delete", "Recover", "Purge"
   ]
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

resource "azurerm_key_vault_secret" "datalake-access-key-secret" {
   depends_on = [ azurerm_key_vault_access_policy.deployer_keyvault_policy]
   name         = "datalake-access-key"
   value = azurerm_storage_account.datalake_storage_account.primary_access_key
   key_vault_id = azurerm_key_vault.key_vault.id
}


resource "azurerm_databricks_workspace" "databricks_workspace" {
  name                = substr("databricks-workspace-${local.resource_prefix}", 0, 63)
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  sku                 = "trial"

  tags = {
    Environment = "Production"
  }
}


resource "databricks_cluster" "databricks_cluster" {
  cluster_name            = substr("databricks-cluster-${local.resource_prefix}", 0, 63)
  node_type_id            = "Standard_F4"
  spark_version           = "12.2.x-scala2.12"
  autotermination_minutes = 15
  num_workers             = 1
  data_security_mode = "SINGLE_USER"
  /* lifecycle {

    create_before_destroy = true
  } */
}

resource "azurerm_data_factory_linked_service_azure_databricks" "databricks_cluster_linked_servie" {
  name                = "datbricksClusterLinkedService"
  data_factory_id     = azurerm_data_factory.data_factory.id
  existing_cluster_id = databricks_cluster.databricks_cluster.cluster_id
  msi_work_space_resource_id = azurerm_databricks_workspace.databricks_workspace.id
  adb_domain   = "https://${azurerm_databricks_workspace.databricks_workspace.workspace_url}"
}

resource "azurerm_role_assignment" "df_databricks_role_assignement" {  
  for_each = toset(["Contributor", "Storage Blob Data Owner"])
  role_definition_name               = each.value

  scope                = azurerm_databricks_workspace.databricks_workspace.id   
  principal_id         = azurerm_data_factory.data_factory.identity[0].principal_id  
}  

resource "azurerm_role_assignment" "deployer_databricks_role_assignement" {  
  for_each = toset(["Contributor", "Storage Blob Data Owner"])
  role_definition_name               = each.value

  scope                = azurerm_databricks_workspace.databricks_workspace.id   
  principal_id         = data.azuread_client_config.current.object_id  
}  

resource "time_sleep" "databricks_role_assignment_sleep" {
  create_duration = "60s"

  triggers = {
    role_assignment = azurerm_role_assignment.deployer_databricks_role_assignement["Contributor"].id
  }
}

data "databricks_current_user" "current" {
  depends_on = [ azurerm_role_assignment.deployer_databricks_role_assignement ]
}

resource "databricks_notebook" "notebook" {
  path     = "${data.databricks_current_user.current.home}/pipeline/copyFromBronzeToSilver.py"
  language = "PYTHON"
  source   = "../databricks/src/copyFromBronzeToSilver.py"
}

resource "azuread_application" "databricks_service_application" {
  display_name = "databricks_service_application"
  identifier_uris  = ["api://databricks_service_application"]
  owners       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal" "aad_service_sp" {
  application_id               = azuread_application.databricks_service_application.application_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]
}

resource "azuread_service_principal_password" "service_sp_pswd" {
  service_principal_id = azuread_service_principal.aad_service_sp.object_id
}


resource "azurerm_role_assignment" "databricks_dl_role_assignment" {  
  for_each = toset(["Contributor", "Storage Blob Data Owner"])
  role_definition_name               = each.value

  scope                = azurerm_storage_account.datalake_storage_account.id   
  principal_id         = azuread_service_principal.aad_service_sp.object_id 
}

resource "azurerm_key_vault_secret" "adb_client_id" {
   depends_on = [ azurerm_key_vault_access_policy.deployer_keyvault_policy]
   name         = "client-id"
   value = azuread_service_principal.aad_service_sp.application_id
   key_vault_id = azurerm_key_vault.key_vault.id
}

resource "azurerm_key_vault_secret" "adb_client_secret" {
   depends_on = [ azurerm_key_vault_access_policy.deployer_keyvault_policy]
   name         = "client-secret"
   value = azuread_service_principal_password.service_sp_pswd.value
   key_vault_id = azurerm_key_vault.key_vault.id
}

resource "azurerm_key_vault_secret" "adb_tenant_id" {
   depends_on = [ azurerm_key_vault_access_policy.deployer_keyvault_policy]
   name         = "client-tenant-id"
   value = data.azuread_client_config.current.tenant_id
   key_vault_id = azurerm_key_vault.key_vault.id
}

resource "databricks_secret_scope" "kv" {
  name = "keyvault-managed"
  depends_on = [ databricks_cluster.databricks_cluster, azurerm_key_vault.key_vault ]

  keyvault_metadata {
    resource_id = azurerm_key_vault.key_vault.id
    dns_name    = azurerm_key_vault.key_vault.vault_uri
  }
}

 resource "databricks_mount" "databricks_mound" {
  depends_on = [ databricks_cluster.databricks_cluster, azurerm_key_vault.key_vault ]
  name = "datalake_mount"
  cluster_id = databricks_cluster.databricks_cluster.cluster_id
  uri = "abfss://${azurerm_storage_data_lake_gen2_filesystem.adls.name}@${azurerm_storage_account.datalake_storage_account.name}.dfs.core.windows.net"
  extra_configs = {
    "fs.azure.account.auth.type" : "OAuth",
    #"fs.azure.account.auth.type.${azurerm_storage_account.datalake_storage_account.name}.dfs.core.windows.net" : "OAuth",
    "fs.azure.account.oauth.provider.type" : "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider",
    "fs.azure.account.oauth2.client.id" : azuread_service_principal.aad_service_sp.application_id
    "fs.azure.account.oauth2.client.secret" : "{{secrets/keyvault-managed/client-secret}}",
    "fs.azure.account.oauth2.client.endpoint" : "https://login.microsoftonline.com/${data.azuread_client_config.current.tenant_id}/oauth2/token",
    "fs.azure.createRemoteFileSystemDuringInitialization" : "false",
  }
} 