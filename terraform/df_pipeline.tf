
resource "azurerm_data_factory_pipeline" "taxi_green_copy" {
  name            = "pipeline1"
  data_factory_id = azurerm_data_factory.df.id
  variables = {
    "bob" = "item1"
  }
  activities_json = <<JSON
[
    {
        "name": "Copy Green Taxi Data",
        "type": "Copy",
        "dependsOn": [],
        "policy": {
            "timeout": "12:00:00",
            "retry": 0,
            "retryIntervalInSeconds": 30,
            "secureOutput": false,
            "secureInput": false
        },
        "userProperties": [],
        "typeProperties": {
            "source": {
                "type": "ParquetSource",
                "storeSettings": {
                    "type": "AzureBlobStorageReadSettings",
                    "recursive": true,
                    "wildcardFileName": "*.parquet",
                    "enablePartitionDiscovery": true
                },
                "formatSettings": {
                    "type": "ParquetReadSettings"
                }
            },
            "sink": {
                "type": "ParquetSink",
                "storeSettings": {
                    "type": "AzureBlobStorageWriteSettings"
                },
                "formatSettings": {
                    "type": "ParquetWriteSettings"
                }
            },
            "enableStaging": false,
            "translator": {
                "type": "TabularTranslator",
                "typeConversion": true,
                "typeConversionSettings": {
                    "allowDataTruncation": true,
                    "treatBooleanAsNumber": false
                }
            }
        },
        "inputs": [
            {
                "referenceName": "green_taxi",
                "type": "DatasetReference",
                "parameters": {}
            }
        ],
        "outputs": [
            {
                "referenceName": "Parquet1",
                "type": "DatasetReference",
                "parameters": {}
            }
        ]
    }
]
  JSON
}

resource "azurerm_data_factory_linked_service_azure_blob_storage" "NYCTaxi" {
  name              = "NYCTaxi"
  data_factory_id   = azurerm_data_factory.df.id
  connection_string = "https://azureopendatastorage.blob.core.windows.net/nyctlc"

}

resource "azurerm_data_factory_dataset_parquet" "yellow_taxi" {
  name                = "yellow_taxi"
  data_factory_id     = azurerm_data_factory.df.id
  linked_service_name = azurerm_data_factory_linked_service_azure_blob_storage.NYCTaxi.name

  azure_blob_storage_location {
    path      = "yellow"
    container = "nyctlc"
  }
  compression_codec = "snappy"

  schema_column {
    name = "vendorID"
    type = "UTF8"
  }
}

resource "azurerm_data_factory_dataset_parquet" "green_taxi" {
  name                = "green_taxi"
  data_factory_id     = azurerm_data_factory.example.id
  linked_service_name = azurerm_data_factory_linked_service_azure_blob_storage.NYCTaxi.name

  azure_blob_storage_location {
    path      = "green"
    container = "nyctlc"
  }
  compression_codec = "snappy"

  schema_column {
    name = "vendorID"
    type = "UTF8"
  }
  // Add the remaining schema fields
}

resource "azurerm_data_factory_dataset_parquet" "taxi_fhv" {
  name                = "taxi_fhv"
  data_factory_id     = azurerm_data_factory.example.id
  linked_service_name = azurerm_data_factory_linked_service_azure_blob_storage.NYCTaxi.name

  azure_blob_storage_location {
    path      = "fhv"
    container = "nyctlc"
  }
  compression_codec = "snappy"

  schema_column {
    name = "vendorID"
    type = "UTF8"
  }
  // Add the remaining schema fields
}




resource "azurerm_data_factory_linked_service_azure_blob_storage" "Data" {
  name              = "Data"
  data_factory_id   = azurerm_data_factory.df.id
  connection_string = azurerm_resource_group.rg_prod.primary_connection_string
}

resource "azurerm_data_factory_dataset" "Parquet1" {
  name                = "Parquet1"
  data_factory_id     = azurerm_data_factory.example.id
  linked_service_name = azurerm_data_factory_linked_service.Data.name
  type                = "Parquet"
  annotations         = []
  type_properties {
    location {
      type      = "AzureBlobStorageLocation"
      container = "raw-data"
    }
    compression_codec = "snappy"
  }
  schema = []
}
