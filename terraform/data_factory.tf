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
