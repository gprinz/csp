resource "azurerm_synapse_workspace" "example" {
  name                                 = "synapse6335"
  resource_group_name                  = azurerm_resource_group.ml_rg.name
  location                             = azurerm_resource_group.ml_rg.location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.fs.id
  sql_administrator_login              = "sqladminuser"

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

  depends_on = [azurerm_key_vault_access_policy.workspace_policy]
}

resource "azurerm_synapse_workspace_aad_admin" "example" {
  synapse_workspace_id = azurerm_synapse_workspace.example.id
  login                = "AzureAD Admin"
  object_id            = data.azurerm_client_config.current.object_id
  tenant_id            = data.azurerm_client_config.current.tenant_id

  depends_on = [azurerm_synapse_workspace_key.example]
}

resource "azurerm_role_assignment" "synapse_blob_reader" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_synapse_workspace.example.identity[0].principal_id
}