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

resource "azurerm_data_factory" "data_factory" {
  name                = substr("df-${local.resource_prefix}", 0, 63)
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
  name                     = "bigdata-project-kv"
  location                 = azurerm_resource_group.resource_group.location
  resource_group_name      = azurerm_resource_group.resource_group.name
  tenant_id                = data.azuread_client_config.current.tenant_id
  sku_name                 = "standard"
  purge_protection_enabled = true
} 

resource "azurerm_key_vault_access_policy" "deployer_keyvault_policy" {
   key_vault_id = azurerm_key_vault.key_vault.id
   tenant_id    = data.azuread_client_config.current.tenant_id
   object_id    = data.azuread_client_config.current.object_id
   secret_permissions = [
     "Get", "List", "Set", "Delete", "Recover"
   ]
}
resource "azurerm_key_vault_access_policy" "df_keyvault_policy" {
   key_vault_id = azurerm_key_vault.key_vault.id
   tenant_id    = azurerm_data_factory.data_factory.identity[0].tenant_id
   object_id    = azurerm_data_factory.data_factory.identity[0].principal_id

   secret_permissions = [
     "Get", "List", "Set", "Delete", "Recover"
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
  name                = substr("databricks-${local.resource_prefix}", 0, 63)
  resource_group_name = azurerm_resource_group.resource_group.name
  location            = azurerm_resource_group.resource_group.location
  sku                 = "trial"

  tags = {
    Environment = "Production"
  }
}

provider "databricks" {
  host = azurerm_databricks_workspace.databricks_workspace.workspace_url
}

/* data "databricks_node_type" "smallest" {
  local_disk = true
}

# Use the latest Databricks Runtime
# Long Term Support (LTS) version.
data "databricks_spark_version" "latest_lts" {
  long_term_support = true
  depends_on = [ azurerm_databricks_workspace.databricks_workspace ]
} */

resource "databricks_cluster" "databricks_cluster" {
  cluster_name            = substr("cluster-${local.resource_prefix}", 0, 63)
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

data "databricks_current_user" "current" {}

resource "databricks_notebook" "notebook" {
  path     = "${data.databricks_current_user.current.home}/pipeline/copyFromBronzeToSilver.py"
  language = "PYTHON"
  source   = "../copyFromBronzeToSilver.py"
}

resource "databricks_secret_scope" "terraform" {
    name                     = "application"
    initial_manage_principal = "users"
}

resource "databricks_secret" "service_principal_key" {
    key          = "service_principal_key"
    string_value = "${var.ARM_CLIENT_SECRET}"
    scope        = databricks_secret_scope.terraform.name
}

resource "databricks_azure_adls_gen2_mount" "datalake_mount" {
    container_name         = "datalake"
    storage_account_name   = azurerm_storage_account.datalake_storage_account.name
    mount_name             = "datalake"
    tenant_id              = data.azuread_client_config.current.tenant_id
    client_id              = data.azuread_client_config.current.client_id
    client_secret_scope    = databricks_secret_scope.terraform.name
    client_secret_key      = databricks_secret.service_principal_key.key
    initialize_file_system = true
}