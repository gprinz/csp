# Storage account configuration
resource "azurerm_storage_account" "datalake" {
  name                     = "sadl${local.current_year}ch"
  location                 = azurerm_resource_group.ml_rg.location
  resource_group_name      = azurerm_resource_group.ml_rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Create Data Lake Gen2 Filesystem
resource "azurerm_storage_data_lake_gen2_filesystem" "dl_fs" {
  name               = "dlfs-${local.current_year}-ch"
  storage_account_id = azurerm_storage_account.datalake.id
}

resource "azurerm_data_factory" "df" {
  name                = "df-${local.current_year}-ch"
  resource_group_name = azurerm_resource_group.rg_prod.name
  location            = azurerm_resource_group.rg_prod.location
}

resource "azurerm_data_factory_linked_service_azure_blob_storage" "source" {
  name              = "Open Data"
  data_factory_id   = azurerm_data_factory.df.id
  connection_string = "DefaultEndpointsProtocol=https;AccountName=azureopendatastorage;EndpointSuffix=blob.core.windows.net"
}

resource "azurerm_data_factory_dataset_parquet" "source_parquet" {
  name                = "source-parquet"
  data_factory_id     = azurerm_data_factory.df.id
  linked_service_name = azurerm_data_factory_linked_service_azure_blob_storage.source.name

  azure_blob_storage_location {
    container = "nyctlc"
    path      = "yellow/"
  }
}

resource "azurerm_data_factory_linked_service_data_lake_storage_gen2" "destination" {
  name                 = "destination-parquet"
  data_factory_id      = azurerm_data_factory.df.id
  url                  = azurerm_storage_data_lake_gen2_filesystem.dl_fs.primary_blob_endpoint
  use_managed_identity = true
}