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

resource "azurerm_data_factory_linked_service_azure_blob_storage" "source" {
  name              = "example-linked-service-source"
  data_factory_id   = azurerm_data_factory.example.id
  connection_string = "DefaultEndpointsProtocol=https;AccountName=stmdwpublic;EndpointSuffix=blob.core.windows.net"
}


resource "azurerm_data_factory_dataset_azure_blob" "source_dataset" {
  name                = "example-source-dataset"
  data_factory_id     = azurerm_data_factory.example.id
  linked_service_name = azurerm_data_factory_linked_service_azure_blob_storage.source.name
  filename            = "*.parquet"
}




resource "azurerm_data_factory_linked_service_data_lake_storage_gen2" "example" {
  name                 = "example"
  data_factory_id      = azurerm_data_factory.example.id
  url                  = azurerm_storage_data_lake_gen2_filesystem.example.url
  use_managed_identity = true
}


# Datasets
resource "azurerm_data_factory_dataset_azure_blob" "destination_dataset" {
  name                = "example-destination-dataset"
  data_factory_id     = azurerm_data_factory.example.id
  linked_service_name = azurerm_data_factory_linked_service_data_lake_storage_gen2.example.name
}

resource "azurerm_data_factory_pipeline" "example_pipeline" {
  name            = "example-pipeline"
  data_factory_id = azurerm_data_factory.example.id

  dynamic "activity" {
    for_each = [
      {
        name    = "GetMetadata"
        type    = "GetMetadata"
        inputs  = [azurerm_data_factory_dataset_azure_data_lake_storage_gen2.source_dataset.id]
        outputs = []
        settings = jsonencode({
          fieldList = ["Child Items"]
        })
      },
      {
        name = "ForEach"
        type = "ForEach"
        settings = jsonencode({
          items = "@activity('GetMetadata').output.childItems"
        })
        activities = [
          {
            name    = "CopyData"
            type    = "Copy"
            inputs  = [azurerm_data_factory_dataset_azure_data_lake_storage_gen2.source_dataset.id]
            outputs = [azurerm_data_factory_dataset_azure_blob.destination_dataset.id]
            settings = jsonencode({
              source = {
                type = "ParquetSource"
              },
              sink = {
                type = "BlobSink"
              }
            })
          }
        ]
      }
    ]
  }
}

data "azurerm_client_config" "example" {}