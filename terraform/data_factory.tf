# Storage account configuration
resource "azurerm_storage_account" "datalake" {
  name                     = "sadl${local.current_year}ch"
  location                 = azurerm_resource_group.ml_rg.location
  resource_group_name      = azurerm_resource_group.ml_rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create Data Lake Gen2 Filesystem
resource "azurerm_storage_data_lake_gen2_filesystem" "example" {
  name               = "dlfs-${local.current_year}-ch"
  storage_account_id = azurerm_storage_account.datalake.id
}

resource "azurerm_data_factory" "example" {
  name                = "df-${local.current_year}-ch"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
}

resource "azurerm_data_factory_linked_service_azure_blob_storage" "source" {
  name              = "example-linked-service-source"
  data_factory_id   = azurerm_data_factory.example.id
  connection_string = "DefaultEndpointsProtocol=https;AccountName=stmdwpublic;EndpointSuffix=blob.core.windows.net"
}
