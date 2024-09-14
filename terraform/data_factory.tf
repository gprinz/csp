// Define a user-assigned managed identity
resource "azurerm_user_assigned_identity" "uai_df" {
  name                = "uai-datafactory"
  resource_group_name = azurerm_resource_group.rg_prod.name
  location            = azurerm_resource_group.rg_prod.location
}

// Define an Azure Data Factory instance
resource "azurerm_data_factory" "df" {
  name                = "df-${local.current_year}-ch"
  resource_group_name = azurerm_resource_group.rg_prod.name
  location            = azurerm_resource_group.rg_prod.location

  identity {
    type = "SystemAssigned"
  }
}

# Assign Synapse Administrator role to the managed identity
resource "azurerm_role_assignment" "df_admin_role" {
  principal_id         = azurerm_data_factory.df.identity[0].principal_id
  role_definition_name = "Contributor"
  scope                = "/subscriptions/796313f9-881f-4bee-bd46-ba6ad10afbb4"
}

resource "azurerm_data_factory" "adf" {
  name                = "adf-${local.current_year}"
  resource_group_name = azurerm_resource_group.rg_synapse.name
  location            = azurerm_resource_group.rg_synapse.location

  identity {
    type = "SystemAssigned"
  }
}


resource "azurerm_role_assignment" "adf_blob_contributor" {
  scope                = azurerm_storage_account.synapse.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_data_factory.adf.identity.principal_id
}