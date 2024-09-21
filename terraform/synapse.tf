# Resource Group for production
resource "azurerm_resource_group" "rg_data_platform" {
  name     = "rgdp${local.current_year}ch"
  location = "West Europe"
}

# Storage account configuration
resource "azurerm_storage_account" "data_lake" {
  name                     = "sadataplatform${local.current_year}ch"
  location                 = azurerm_resource_group.rg_data_platform.location
  resource_group_name      = azurerm_resource_group.rg_data_platform.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true
}

# Data Lake Gen2 Filesystem configuration
resource "azurerm_storage_data_lake_gen2_filesystem" "data_lake_fs" {
  name               = "datalake"
  storage_account_id = azurerm_storage_account.data_lake.id
}

# Directories variable
variable "directories" {
  type    = list(string)
  default = ["green", "yellow", "fhv"]
}

# Data Lake Gen2 Path for directories
resource "azurerm_storage_data_lake_gen2_path" "data_lake_directories" {
  for_each           = toset(var.directories)
  filesystem_name    = azurerm_storage_data_lake_gen2_filesystem.data_lake_fs.name
  storage_account_id = azurerm_storage_account.data_lake.id
  path               = each.value
  resource           = "directory"
}

# Synapse Workspace configuration
resource "azurerm_synapse_workspace" "synapse_workspace" {
  name                                 = "synapseworkspace${local.current_year}ch"
  resource_group_name                  = azurerm_resource_group.rg_data_platform.name
  location                             = azurerm_resource_group.rg_data_platform.location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_data_lake_gen2_filesystem.data_lake_fs.id
  sql_administrator_login              = "sqladminuser"

  identity {
    type = "SystemAssigned"
  }
}

# Role assignment for Synapse Blob Reader
resource "azurerm_role_assignment" "synapse_contributor_role" {
  scope                = data.azurerm_subscription.primary.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_synapse_workspace.synapse_workspace.identity[0].principal_id
}


# Data source to get the specific AD user
data "azuread_user" "example_user" {
  user_principal_name = "raphaelprinz@outlook.com"
}

# Assign 'Synapse Contributor' role to the user
resource "azurerm_role_assignment" "synapse_contributor" {
  scope                = azurerm_synapse_workspace.synapse_workspace.id
  role_definition_name = "Synapse Administrator" # You can also use 'Synapse Administrator' or 'SQL Contributor'
  principal_id         = data.azuread_user.example_user.id
}
