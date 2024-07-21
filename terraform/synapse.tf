
# Resource Group for production
resource "azurerm_resource_group" "rg_synapse" {
  name     = "rgsyn${local.current_year}ch3"
  location = "West Europe"
}

resource "azurerm_synapse_workspace" "synapse" {
  name                                 = "shng45"
  resource_group_name                  = azurerm_resource_group.rg_synapse.name
  location                             = azurerm_resource_group.rg_synapse.location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_account.synapse.id
  sql_administrator_login              = var.SYNAPSE_ADMIN_USER
  sql_administrator_login_password     = var.SYNAPSE_ADMIN_PWD

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_synapse_sql_pool" "sql" {
  name                 = "dwh"
  synapse_workspace_id = azurerm_synapse_workspace.synapse.id
  sku_name             = "DW100c"
  create_mode          = "Default"
  storage_account_type = "GRS"
}