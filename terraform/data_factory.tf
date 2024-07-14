provider "azurerm" {
  features {}
}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "data-factory-resources"
  location = "West Europe"
}

# Data Factory
resource "azurerm_data_factory" "data_factory" {
  name                = "data-factory"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

# Data Factory Linked Service for Blob Storage
resource "azurerm_data_factory_linked_service_azure_blob_storage" "blob_storage" {
  name            = "blobstorage-linkedservice"
  data_factory_id = azurerm_data_factory.data_factory.id

  connection_string = "DefaultEndpointsProtocol=https;AccountName=youraccountname;AccountKey=youraccountkey;EndpointSuffix=core.windows.net"
}

# Data Factory Dataset for Transactions Source Data
resource "azurerm_data_factory_dataset_parquet" "transactions_source" {
  name                = "transactions-source-dataset"
  data_factory_id     = azurerm_data_factory.data_factory.id
  linked_service_name = azurerm_data_factory_linked_service_azure_blob_storage.blob_storage.name

  folder = "feature-store-prp/datasources/transactions-source"
}

resource "azurerm_data_factory_pipeline" "pipeline" {
  name            = "data-pipeline"
  data_factory_id = azurerm_data_factory.example.id

  activities_json = <<JSON
  [
    {
      "name": "CopyFromBlobToADLS",
      "type": "Copy",
      "dependsOn": [],
      "typeProperties": {
        "source": {
          "type": "ParquetSource"
        },
        "sink": {
          "type": "AzureDataLakeStoreSink",
          "linkedServiceName": {
            "referenceName": "${azurerm_data_factory_linked_service_azure_data_lake_store.adls.name}",
            "type": "LinkedServiceReference"
          }
        }
      },
      "inputs": [
        {
          "referenceName": "${azurerm_data_factory_dataset_parquet.transactions_source.name}",
          "type": "DatasetReference"
        }
      ],
      "outputs": [
        {
          "referenceName": "${azurerm_data_factory_dataset_parquet.transactions_source.name}",
          "type": "DatasetReference"
        }
      ]
    }
  ]
  JSON
}
# Data Factory Trigger for Daily Execution
resource "azurerm_data_factory_trigger_schedule" "daily_trigger" {
  name            = "daily-trigger"
  data_factory_id = azurerm_data_factory.example.id

  pipeline_name = azurerm_data_factory_pipeline.pipeline.name

  frequency = "Day"
  interval  = 1
}

# Data Lake Store (if not existing)
resource "azurerm_data_lake_store" "adls" {
  name                = "datalake"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
}

# Data Factory Linked Service for ADLS Gen2
resource "azurerm_data_factory_linked_service_azure_data_lake_store" "adls" {
  name                = "adls-linkedservice"
  resource_group_name = azurerm_resource_group.rg.name
  data_factory_name   = azurerm_data_factory.data_factory.name

  data_lake_store_id = azurerm_data_lake_store.adls.id
}

# Permissions for Data Factory to access Data Lake Store
resource "azurerm_role_assignment" "role_assignment" {
  principal_id         = azurerm_data_factory.data_factory.identity.0.principal_id
  role_definition_name = "Contributor"
  scope                = azurerm_data_lake_store.adls.id
}
