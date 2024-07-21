resource "azurerm_resource_group_template_deployment" "NYCTaxi" {
  name                = "NYCTaxi"
  resource_group_name = azurerm_resource_group.rg_prod.name
  deployment_mode     = "Incremental"
  parameters_content = jsonencode({
    "dataFactoryName" = {
      value = azurerm_data_factory.df.name
    }
  })

  template_content = <<TEMPLATE
  {
    "$schema": "http://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
        "parameters": {
        "factoryName": {
            "type": "string",
            "metadata": "Data Factory name",
            "defaultValue": "df-2024-ch"
        },
    },
        "variables": {
        "factoryId": "[concat('Microsoft.DataFactory/factories/', parameters('factoryName'))]"
    },
    "resources": [
      {
            "name": "[concat(parameters('factoryName'), '/NYCTaxi')]",
            "type": "Microsoft.DataFactory/factories/linkedServices",
            "apiVersion": "2018-06-01",
            "properties": {
                "annotations": [],
                "type": "AzureBlobStorage",
                "typeProperties": {
                    "containerUri": "https://azureopendatastorage.blob.core.windows.net/nyctlc",
                    "authenticationType": "Anonymous"
                }
            },
            "dependsOn": []
  }
  TEMPLATE
}

resource "azurerm_data_factory_dataset_parquet" "yellow_taxi" {
  name                = "yellow_taxi"
  data_factory_id     = azurerm_data_factory.df.id
  linked_service_name = azurerm_resource_group_template_deployment.NYCTaxi.name

  azure_blob_storage_location {
    path      = "yellow"
    container = "nyctlc"
  }
  compression_codec = "snappy"

  schema_column {
    name = "vendorID"
    type = "String"
  }
}

resource "azurerm_data_factory_dataset_parquet" "green_taxi" {
  name                = "green_taxi"
  data_factory_id     = azurerm_data_factory.df.id
  linked_service_name = azurerm_resource_group_template_deployment.NYCTaxi.name

  azure_blob_storage_location {
    path      = "green"
    container = "nyctlc"
  }
  compression_codec = "snappy"

  schema_column {
    name = "vendorID"
    type = "String"
  }
  // Add the remaining schema fields
}

resource "azurerm_data_factory_dataset_parquet" "taxi_fhv" {
  name                = "taxi_fhv"
  data_factory_id     = azurerm_data_factory.df.id
  linked_service_name = azurerm_resource_group_template_deployment.NYCTaxi.name

  azure_blob_storage_location {
    path      = "fhv"
    container = "nyctlc"
  }
  compression_codec = "snappy"

  schema_column {
    name = "vendorID"
    type = "String"
  }
  // Add the remaining schema fields
}




resource "azurerm_data_factory_linked_service_azure_blob_storage" "Data" {
  name              = "Data"
  data_factory_id   = azurerm_data_factory.df.id
  connection_string = azurerm_storage_account.raw_data.primary_connection_string
}

resource "azurerm_data_factory_dataset_parquet" "Parquet1" {
  name                = "Parquet1"
  data_factory_id     = azurerm_data_factory.df.id
  linked_service_name = azurerm_data_factory_linked_service_azure_blob_storage.Data.name

  azure_blob_storage_location {
    container = "raw-data"
  }
  compression_codec = "snappy"

  schema_column {
    name = "vendorID"
    type = "String"
  }
}


