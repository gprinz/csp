# Resource Group for production
resource "azurerm_resource_group" "rg_synapse" {
  name     = "rgsyn${local.current_year}ch6"
  location = "West Europe"
}

# Storage account configuration
resource "azurerm_storage_account" "synapse" {
  name                     = "sasynapse${local.current_year}ch"
  location                 = azurerm_resource_group.rg_synapse.location
  resource_group_name      = azurerm_resource_group.rg_synapse.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = "true"
}


resource "azurerm_storage_data_lake_gen2_filesystem" "file" {
  name               = "example"
  storage_account_id = azurerm_storage_account.synapse.id
}

# Key Vault configuration
resource "azurerm_key_vault" "kv2" {
  name                     = "kv-${local.current_year}-ch400"
  location                 = azurerm_resource_group.ml_rg.location
  resource_group_name      = azurerm_resource_group.ml_rg.name
  tenant_id                = data.azurerm_client_config.current.tenant_id
  sku_name                 = "premium"
  purge_protection_enabled = true
}

resource "azurerm_key_vault_access_policy" "deployer" {
  key_vault_id = azurerm_key_vault.kv2.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Create", "Get", "Delete", "Purge", "GetRotationPolicy"
  ]
}

resource "azurerm_key_vault_key" "example" {
  name         = "workspaceencryptionkey"
  key_vault_id = azurerm_key_vault.kv2.id
  key_type     = "RSA"
  key_size     = 2048
  key_opts = [
    "unwrapKey",
    "wrapKey"
  ]
  depends_on = [
    azurerm_key_vault_access_policy.deployer
  ]
}

resource "azurerm_synapse_workspace" "example" {
  name                                 = "synapse6335"
  resource_group_name                  = azurerm_resource_group.rg_synapse.name
  location                             = azurerm_resource_group.rg_synapse.location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.file.id

  customer_managed_key {
    key_versionless_id = azurerm_key_vault_key.example.versionless_id
    key_name           = "enckey"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Env = "production"
  }
}

resource "azurerm_key_vault_access_policy" "workspace_policy" {
  key_vault_id = azurerm_key_vault.kv2.id
  tenant_id    = azurerm_synapse_workspace.example.identity[0].tenant_id
  object_id    = azurerm_synapse_workspace.example.identity[0].principal_id

  key_permissions = [
    "Get", "WrapKey", "UnwrapKey"
  ]
}

resource "azurerm_synapse_workspace_key" "example" {
  customer_managed_key_versionless_id = azurerm_key_vault_key.example.versionless_id
  synapse_workspace_id                = azurerm_synapse_workspace.example.id
  active                              = true
  customer_managed_key_name           = "enckey"
}

resource "azurerm_synapse_workspace_aad_admin" "example" {
  synapse_workspace_id = azurerm_synapse_workspace.example.id
  login                = "AzureAD Admin"
  object_id            = data.azurerm_client_config.current.object_id
  tenant_id            = data.azurerm_client_config.current.tenant_id

  depends_on = [azurerm_synapse_workspace_key.example]
}

resource "azurerm_role_assignment" "synapse_blob_reader" {
  scope                = azurerm_storage_account.synapse.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_synapse_workspace.example.identity[0].principal_id
}
