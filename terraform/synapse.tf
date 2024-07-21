
# Resource Group for production
resource "azurerm_resource_group" "rg_synapse" {
  name     = "rgsyn${local.current_year}ch6"
  location = "West Europe"
}

# Storage account configuration
resource "azurerm_storage_account" "synapse" {
  name                     = "sasynapse${local.current_year}ch"
  location                 = azurerm_resource_group.rg_prod.location
  resource_group_name      = azurerm_resource_group.rg_prod.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_data_lake_gen2_filesystem" "file" {
  name               = "example"
  storage_account_id = azurerm_storage_account.synapse.id
}

resource "azurerm_synapse_workspace" "synapse" {
  name                                 = "synapse6335"
  resource_group_name                  = azurerm_resource_group.rg_synapse.name
  location                             = azurerm_resource_group.rg_synapse.location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.file.id
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