# Create Logic App
resource "azurerm_logic_app_workflow" "example" {
  name                = "workflow1"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

# Define HTTP Trigger with schema
resource "azurerm_logic_app_trigger_http_request" "example" {
  name         = "new-blob-trigger"
  logic_app_id = azurerm_logic_app_workflow.example.id

  schema = <<SCHEMA
{
  "type": "object",
  "properties": {
    "url": {
      "type": "string"
    }
  }
}
SCHEMA
}

## Define Logic App Action to get blob content
#resource "azurerm_logic_app_action_http" "get_blob_content" {
#  name         = "Get_blob_content"
#  logic_app_id = azurerm_logic_app_workflow.example.id
#    method = "GET"
#    uri = "https://${azurerm_storage_account.source_storage.name}.blob.core.windows.net/${azurerm_storage_container.source_container.name}/{blobName}"
#
#
#    headers = {
#      "x-ms-version" = "2019-12-12"
#    }
#
#}
#
## Define Logic App Action to create blob in destination
#resource "azurerm_logic_app_action_http" "create_blob" {
#  name         = "Create_blob_in_destination"
#  logic_app_id = azurerm_logic_app_workflow.example.id
#  method = "PUT"
#      uri = "https://${azurerm_storage_account.destination_storage.name}.blob.core.windows.net/${azurerm_storage_container.destination_container.name}/{blobName}"
#    headers = {
#      "x-ms-version" = "2019-12-12"
#    }
#    body = azurerm_logic_app_action_http.get_blob_content.response_body
#}
