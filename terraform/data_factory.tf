resource "azurerm_data_factory" "adf" {
  name                = "df-${local.current_year}-ch"
  resource_group_name = azurerm_resource_group.rg_prod.name
  location            = azurerm_resource_group.rg_prod.location

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "a3" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_data_factory.adf.identity[0].principal_id
}

resource "azurerm_role_assignment" "a2" {
  principal_id         = azurerm_machine_learning_workspace.ml_workspace.identity[0].principal_id
  role_definition_name = "Contributor"
  scope                = data.azurerm_subscription.primary.id
}