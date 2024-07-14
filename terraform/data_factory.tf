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
  name            = "Open_Data"
  data_factory_id = azurerm_data_factory.df.id
  sas_uri         = "https://azureopendatastorage.blob.core.windows.net/"
}

resource "azurerm_data_factory_dataset_parquet" "source_parquet" {
  name                = "Taxi_Data_Open_Data"
  data_factory_id     = azurerm_data_factory.df.id
  linked_service_name = azurerm_data_factory_linked_service_azure_blob_storage.source.name

  azure_blob_storage_location {
    container = "nyctlc"
    path      = "yellow/"
  }
}

resource "azurerm_data_factory_linked_service_data_lake_storage_gen2" "destination" {
  name                 = "Data_Lake"
  data_factory_id      = azurerm_data_factory.df.id
  url                  = "https://${azurerm_storage_account.datalake.name}.blob.core.windows.net/"
  use_managed_identity = true
}

#resource "azurerm_data_factory_dataset_parquet" "destination_parquet" {
#  name                = "Taxi_Data_Lake"
#  data_factory_id     = azurerm_data_factory.df.id
#  linked_service_name = azurerm_data_factory_linked_service_data_lake_storage_gen2.destination.name
#
#  azure_blob_storage_location {
#    container = "nyctlc"
#    path      = "yellow/"
#  }
#}
#
## Pipeline
#resource "azurerm_data_factory_pipeline" "example_pipeline" {
#  name            = "laod-taxi-data"
#  data_factory_id = azurerm_data_factory.example.name
#
#  dynamic "activity" {
#    for_each = [
#      {
#        name    = "GetMetadata"
#        type    = "GetMetadata"
#        inputs  = [azurerm_data_factory_dataset_azure_data_lake_storage_gen2.source_dataset.id]
#        outputs = []
#        settings = jsonencode({
#          fieldList = ["Child Items"]
#        })
#      },
#      {
#        name = "ForEach"
#        type = "ForEach"
#        settings = jsonencode({
#          items = "@activity('GetMetadata').output.childItems"
#        })
#        activities = [
#          {
#            name    = "CopyData"
#            type    = "Copy"
#            inputs  = [azurerm_data_factory_dataset_parquet.source_parquet.id]
#            outputs = [azurerm_data_factory_dataset_azure_blob.destination_parquet.id]
#            settings = jsonencode({
#              source = {
#                type = "ParquetSource"
#              },
#              sink = {
#                type = "BlobSink"
#              }
#            })
#          }
#        ]
#      }
#    ]
#  }
#}