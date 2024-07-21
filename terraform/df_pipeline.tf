
resource "azurerm_data_factory_pipeline" "txi_green_copy" {
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

resource "azurerm_data_factory_dataset" "yellow_taxi" {
  name                = "yellow_taxi"
  data_factory_id     = azurerm_data_factory.example.id
  linked_service_name = azurerm_data_factory_linked_service.NYCTaxi.name
  type                = "Parquet"
  annotations         = []
  type_properties {
    location {
      type        = "AzureBlobStorageLocation"
      folder_path = "yellow"
      container   = "nyctlc"
    }
    compression_codec = "snappy"
  }
  schema {
    name = "vendorID"
    type = "UTF8"
  }
  // Add the remaining schema fields
}

resource "azurerm_data_factory_dataset" "green_taxi" {
  name                = "green_taxi"
  data_factory_id     = azurerm_data_factory.example.id
  linked_service_name = azurerm_data_factory_linked_service.NYCTaxi.name
  type                = "Parquet"
  annotations         = []
  type_properties {
    location {
      type        = "AzureBlobStorageLocation"
      folder_path = "green"
      container   = "nyctlc"
    }
    compression_codec = "snappy"
  }
  schema {
    name = "vendorID"
    type = "UTF8"
  }
  // Add the remaining schema fields
}

resource "azurerm_data_factory_dataset" "taxi_fhv" {
  name                = "taxi_fhv"
  data_factory_id     = azurerm_data_factory.example.id
  linked_service_name = azurerm_data_factory_linked_service.NYCTaxi.name
  type                = "Parquet"
  annotations         = []
  type_properties {
    location {
      type        = "AzureBlobStorageLocation"
      folder_path = "fhv"
      container   = "nyctlc"
    }
    compression_codec = "snappy"
  }
  schema {
    name = "vendorID"
    type = "UTF8"
  }
  // Add the remaining schema fields
}

resource "azurerm_data_factory_linked_service" "NYCTaxi" {
  name            = "NYCTaxi"
  data_factory_id = azurerm_data_factory.example.id
  type            = "AzureBlobStorage"
  annotations     = []
  type_properties {
    container_uri       = "https://azureopendatastorage.blob.core.windows.net/nyctlc"
    authentication_type = "Anonymous"
  }
}

resource "azurerm_data_factory_linked_service" "AzureBlobStorage1" {
  name            = "AzureBlobStorage1"
  data_factory_id = azurerm_data_factory.example.id
  type            = "AzureBlobStorage"
  annotations     = []
  type_properties {
    connection_string = var.AzureBlobStorage1_connectionString
  }
}

resource "azurerm_data_factory_linked_service" "AzureBlobStorage2" {
  name            = "AzureBlobStorage2"
  data_factory_id = azurerm_data_factory.example.id
  type            = "AzureBlobStorage"
  annotations     = []
  type_properties {
    connection_string = var.AzureBlobStorage2_connectionString
  }
}

resource "azurerm_data_factory_linked_service" "Data" {
  name            = "Data"
  data_factory_id = azurerm_data_factory.example.id
  type            = "AzureBlobStorage"
  annotations     = []
  type_properties {
    connection_string = var.Data_connectionString
  }
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
