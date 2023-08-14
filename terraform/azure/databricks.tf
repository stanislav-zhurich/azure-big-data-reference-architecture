data "databricks_current_user" "current" {
  depends_on = [databricks_cluster.databricks_cluster]
}

data "databricks_spark_version" "latest" {
  long_term_support = true
  depends_on        = [azurerm_databricks_workspace.databricks_workspace]
}
data "databricks_node_type" "smallest" {
  local_disk = true
  depends_on = [azurerm_databricks_workspace.databricks_workspace]
}

resource "azurerm_databricks_workspace" "databricks_workspace" {
  name                        = substr("databricks-workspace-${local.resource_prefix}", 0, 63)
  resource_group_name         = azurerm_resource_group.resource_group.name
  location                    = azurerm_resource_group.resource_group.location
  sku                         = "standard"
  managed_resource_group_name = "adb_${azurerm_resource_group.resource_group.name}"

  tags = local.tags
}

resource "databricks_mount" "databricks_mound" {
  depends_on = [databricks_cluster.databricks_cluster, azurerm_key_vault.key_vault]
  name       = "datalake_mount"
  cluster_id = databricks_cluster.databricks_cluster.cluster_id
  uri        = "abfss://${azurerm_storage_data_lake_gen2_filesystem.adls.name}@${azurerm_storage_account.datalake_storage_account.name}.dfs.core.windows.net"
  extra_configs = {
    "fs.azure.account.auth.type" : "OAuth",
    "fs.azure.account.oauth.provider.type" : "org.apache.hadoop.fs.azurebfs.oauth2.ClientCredsTokenProvider",
    "fs.azure.account.oauth2.client.id" : azuread_service_principal.aad_service_sp.application_id
    "fs.azure.account.oauth2.client.secret" : "{{secrets/keyvault-managed/client-secret}}",
    "fs.azure.account.oauth2.client.endpoint" : "https://login.microsoftonline.com/${data.azuread_client_config.current.tenant_id}/oauth2/token",
    "fs.azure.createRemoteFileSystemDuringInitialization" : "false",
  }
}

resource "databricks_cluster" "databricks_cluster" {
  cluster_name            = substr("databricks-cluster-${local.resource_prefix}", 0, 63)
  node_type_id            = "Standard_F4"#data.databricks_node_type.smallest.id
  spark_version           = data.databricks_spark_version.latest.id
  autotermination_minutes = 15
  num_workers             = 0
  data_security_mode      = "NO_ISOLATION"
  spark_conf = {
    # Single-node
    "spark.databricks.cluster.profile" : "singleNode"
    "spark.master" : "local[*]"
  }
  custom_tags = {
    "ResourceClass" = "SingleNode"
  }
}


resource "databricks_notebook" "notebooks" {
  for_each  = toset(["/pipeline/schema/patient.py", "/pipeline/copyFromBronzeToSilver.py"])
  path     = "${data.databricks_current_user.current.home}${each.value}"
  language = "PYTHON"
  source   = "../../databricks/src${each.value}"
}

resource "databricks_library" "eventhub_library" {
  cluster_id = databricks_cluster.databricks_cluster.id
  maven {
    coordinates = "com.microsoft.azure:azure-eventhubs-spark_2.12:2.3.22"
    #exclusions = ["org.slf4j:slf4j-log4j12", "log4j:log4j"]
  }
}

resource "azurerm_key_vault_secret" "adb_client_secret" {
  depends_on   = [azurerm_key_vault_access_policy.deployer_keyvault_policy]
  name         = "client-secret"
  value        = azuread_service_principal_password.service_sp_pswd.value
  key_vault_id = azurerm_key_vault.key_vault.id
}

resource "azurerm_key_vault_secret" "adb_tenant_id" {
  depends_on   = [azurerm_key_vault_access_policy.deployer_keyvault_policy]
  name         = "client-tenant-id"
  value        = data.azuread_client_config.current.tenant_id
  key_vault_id = azurerm_key_vault.key_vault.id
}

resource "databricks_secret_scope" "kv" {
  name                     = "keyvault-managed"
  depends_on               = [databricks_cluster.databricks_cluster, azurerm_key_vault.key_vault]
  initial_manage_principal = "users"

  keyvault_metadata {
    resource_id = azurerm_key_vault.key_vault.id
    dns_name    = azurerm_key_vault.key_vault.vault_uri
  }
}

resource "azuread_application" "databricks_service_application" {
  display_name    = "databricks_service_application"
  identifier_uris = ["api://databricks_service_application"]
  owners          = [data.azuread_client_config.current.object_id]
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
  for_each             = toset(["Contributor", "Storage Blob Data Owner"])
  role_definition_name = each.value

  scope        = azurerm_storage_account.datalake_storage_account.id
  principal_id = azuread_service_principal.aad_service_sp.object_id
}

resource "azurerm_key_vault_secret" "adb_client_id" {
  depends_on   = [azurerm_key_vault_access_policy.deployer_keyvault_policy]
  name         = "client-id"
  value        = azuread_service_principal.aad_service_sp.application_id
  key_vault_id = azurerm_key_vault.key_vault.id
}

resource "azurerm_role_assignment" "deployer_databricks_role_assignement" {
  for_each             = toset(["Contributor", "Storage Blob Data Owner"])
  role_definition_name = each.value

  scope        = azurerm_databricks_workspace.databricks_workspace.id
  principal_id = data.azuread_client_config.current.object_id
}

resource "time_sleep" "databricks_role_assignment_sleep" {
  create_duration = "60s"

  triggers = {
    role_assignment = azurerm_role_assignment.deployer_databricks_role_assignement["Contributor"].id
  }
}

resource "azurerm_key_vault_access_policy" "adb_keyvault_policy" {
  key_vault_id = azurerm_key_vault.key_vault.id
  tenant_id    = data.azuread_client_config.current.tenant_id
  object_id    = azuread_service_principal.aad_service_sp.object_id

  secret_permissions = [
    "Get", "List", "Set", "Delete", "Recover", "Purge"
  ]
}
