
resource "azurerm_synapse_workspace" "synapse" {
  name                                 = "Synapse Analytics"
  resource_group_name                  = azurerm_resource_group.example.name
  location                             = azurerm_resource_group.example.location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_account.example.id
  sql_administrator_login              = var.SYNAPSE_ADMIN_USER
  sql_administrator_login_password     = var.SYNAPSE_ADMIN_PWD
}

resource "azurerm_synapse_sql_pool" "example" {
  name                 = "DWH"
  synapse_workspace_id = azurerm_synapse_workspace.example.id
  sku_name             = "DW100c"
  create_mode          = "Default"
  storage_account_type = "GRS"
}