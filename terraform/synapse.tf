
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
}

resource "azurerm_storage_data_lake_gen2_filesystem" "file" {
  name               = "example"
  storage_account_id = azurerm_storage_account.synapse.id
}

# Example for allowing all Azure services to connect (not recommended for production)
resource "azurerm_synapse_firewall_rule" "allow_azure_services" {
  name                 = "AllowAllWindowsAzureIps"
  synapse_workspace_id = azurerm_synapse_workspace.synapse.id
  start_ip_address     = "0.0.0.0"
  end_ip_address       = "0.0.0.0"
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

# Assign Synapse Administrator role to the managed identity
resource "azurerm_role_assignment" "contributor_role" {
  principal_id         = azurerm_synapse_workspace.synapse.identity[0].principal_id
  role_definition_name = "Contributor"
  scope                = "/subscriptions/796313f9-881f-4bee-bd46-ba6ad10afbb4"
}

resource "azurerm_synapse_sql_pool" "sql" {
  name                 = "dwh"
  synapse_workspace_id = azurerm_synapse_workspace.synapse.id
  sku_name             = "DW100c"
  create_mode          = "Default"
  storage_account_type = "GRS"
}