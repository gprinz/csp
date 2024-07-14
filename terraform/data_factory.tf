# Create Resource Group
resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "West Europe"
}

# Create Data Lake Storage Account
resource "azurerm_storage_account" "datalake" {
  name                     = "examplestorageacc"
  resource_group_name      = azurerm_resource_group.example.name
  location                 = azurerm_resource_group.example.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  blob_properties {
    container_delete_retention_policy {
      days = 7
    }
  }
}

# Create Data Lake Gen2 Filesystem
resource "azurerm_storage_data_lake_gen2_filesystem" "example" {
  name               = "example-filesystem"
  storage_account_id = azurerm_storage_account.datalake.id
}



resource "azurerm_data_factory" "example" {
  name                = "exampledf"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
}
