
resource "azurerm_synapse_workspace" "synapse" {
  name                                 = "Synapse Analytics"
  resource_group_name                  = azurerm_resource_group.rg_prod.name
  location                             = azurerm_resource_group.rg_prod.location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_account.synapse.id
  sql_administrator_login              = var.SYNAPSE_ADMIN_USER
  sql_administrator_login_password     = var.SYNAPSE_ADMIN_PWD
}

resource "azurerm_synapse_sql_pool" "sql" {
  name                 = "DWH"
  synapse_workspace_id = azurerm_synapse_workspace.synapse.id
  sku_name             = "DW100c"
  create_mode          = "Default"
  storage_account_type = "GRS"
}