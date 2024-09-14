resource "azurerm_data_factory" "adf" {
  name                = "df-${local.current_year}-ch"
  resource_group_name = azurerm_resource_group.rg_synapse.name
  location            = azurerm_resource_group.rg_synapse.location

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "adf_blob_contributor" {
  scope                = azurerm_storage_account.synapse.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_data_factory.adf.identity[0].principal_id
}