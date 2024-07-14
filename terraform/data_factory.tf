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

  connection_string = "DefaultEndpointsProtocol=wbs;AccountName=youraccountname;AccountKey=youraccountkey;EndpointSuffix=core.windows.net"
}

# Data Factory Dataset for Transactions Source Data
resource "azurerm_data_factory_dataset_parquet" "transactions_source" {
  name                = "transactions-source-dataset"
  data_factory_id     = azurerm_data_factory.data_factory.id
  linked_service_name = azurerm_data_factory_linked_service_azure_blob_storage.blob_storage.name

  azure_blob_storage_location {
    container = "feature-store-prp-1"
    path      = "datasources / transactions-source"
    filename  = "test.parquet"
  }

}

#resource "azurerm_data_factory_pipeline" "pipeline" {
#  name            = "data-pipeline"
#  data_factory_id = azurerm_data_factory.data_factory.id
#
#  activities_json = <<JSON
#  [
#    {
#      "name": "CopyFromBlobToADLS",
#      "type": "Copy",
#      "dependsOn": [],
#      "typeProperties": {
#        "source": {
#          "type": "ParquetSource"
#        },
#        "sink": {
#          "type": "AzureDataLakeStoreSink",
#          "linkedServiceName": {
#            "referenceName": "${azurerm_data_factory_linked_service_azure_data_lake_store.adls.name}",
#            "type": "LinkedServiceReference"
#          }
#        }
#      },
#      "inputs": [
#        {
#          "referenceName": "${azurerm_data_factory_dataset_parquet.transactions_source.name}",
#          "type": "DatasetReference"
#        }
#      ],
#      "outputs": [
#        {
#          "referenceName": "${azurerm_data_factory_dataset_parquet.transactions_source.name}",
#          "type": "DatasetReference"
#        }
#      ]
#    }
#  ]
#  JSON
#}
## Data Factory Trigger for Daily Execution
#resource "azurerm_data_factory_trigger_schedule" "daily_trigger" {
#  name            = "daily-trigger"
#  data_factory_id = azurerm_data_factory.data_factory.id
#
#  pipeline_name = azurerm_data_factory_pipeline.pipeline.name
#
#  frequency = "Day"
#  interval  = 1
#}

## Storage Account
#resource "azurerm_storage_account" "example" {
#  name                     = "examplestorageacct"
#  resource_group_name      = azurerm_resource_group.rg.name
#  location                 = azurerm_resource_group.rg.location
#  account_tier             = "Standard"
#  account_replication_type = "LRS"
#  is_hns_enabled           = true # This enables the Data Lake Storage Gen2 capabilities
#}
#
## Storage Container
#resource "azurerm_storage_container" "example" {
#  name                  = "example-container"
#  storage_account_name  = azurerm_storage_account.example.name
#  container_access_type = "private"
#}
#
## Data Factory Linked Service for ADLS Gen2
#resource "azurerm_data_factory_linked_service_azure_data_lake_store" "adls" {
#  name                = "adls-linkedservice"
#  resource_group_name = azurerm_resource_group.rg.name
#  data_factory_name   = azurerm_data_factory.data_factory.name
#
#  data_lake_store_id = azurerm_storage_account.example.id
#}
#
## Permissions for Data Factory to access Data Lake Store
#resource "azurerm_role_assignment" "role_assignment" {
#  principal_id         = azurerm_data_factory.data_factory.identity.0.principal_id
#  role_definition_name = "Contributor"
#  scope                = azurerm_storage_account.example.id
#}
#