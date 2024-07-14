# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "myResourceGroup"
  location = "East US"
}

# Storage Account
resource "azurerm_storage_account" "storageacct" {
  name                     = "mystorageaccount"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  is_hns_enabled           = true
}

# User-assigned Managed Identity
resource "azurerm_user_assigned_identity" "synapse_identity" {
  name                = "mySynapseIdentity"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

# Synapse Analytics Workspace
resource "azurerm_synapse_workspace" "synapse" {
  name                                 = "mySynapseWorkspace"
  resource_group_name                  = azurerm_resource_group.rg.name
  location                             = azurerm_resource_group.rg.location
  storage_data_lake_gen2_filesystem_id = azurerm_storage_account.storageacct.primary_blob_endpoint
  sql_administrator_login              = "sqladminuser"
  sql_administrator_login_password     = "P@ssw0rd1234!" # Ensure this is stored securely

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.synapse_identity.id]
  }
}

# Synapse SQL Pool
resource "azurerm_synapse_sql_pool" "sqlpool" {
  name                 = "mySqlPool"
  synapse_workspace_id = azurerm_synapse_workspace.synapse.id
  sku_name             = "DW100c"
  create_mode          = "Default"
  storage_account_type = "GRS"
}

# Assign a Role to the Managed Identity for access
resource "azurerm_role_assignment" "synapse_role" {
  principal_id         = azurerm_user_assigned_identity.synapse_identity.principal_id
  role_definition_name = "Synapse Contributor"
  scope                = azurerm_synapse_workspace.synapse.id
}