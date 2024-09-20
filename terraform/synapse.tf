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
  account_kind             = "StorageV2"
  is_hns_enabled           = "true"
}

resource "azurerm_storage_data_lake_gen2_filesystem" "fs" {
  name               = "taxi"
  storage_account_id = azurerm_storage_account.synapse.id
}

variable "directories" {
  type    = list(string)
  default = ["green", "yellow", "fhv"]
}

resource "azurerm_storage_data_lake_gen2_path" "directories" {
  for_each           = toset(var.directories)
  filesystem_name    = azurerm_storage_data_lake_gen2_filesystem.fs.name
  storage_account_id = azurerm_storage_account.synapse.id
  path               = each.value
  resource           = "directory"
}



resource "azurerm_synapse_workspace" "example" {
  name                                 = "synapse6335"
  resource_group_name                  = azurerm_resource_group.rg_synapse.name
  location                             = azurerm_resource_group.rg_synapse.location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.fs.id
  sql_administrator_login              = "sqladminuser"

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "synapse_blob_reader" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_synapse_workspace.example.identity[0].principal_id
}