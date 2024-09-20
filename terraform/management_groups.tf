resource "azurerm_management_group" "prod" {
  display_name = "Production"
}

resource "azurerm_management_group" "dev" {
  display_name = "Development"
}

resource "azurerm_management_group" "test" {
  display_name = "Testing"
}

resource "null_resource" "subscription_association" {
  triggers = {
    management_group_id = azurerm_management_group.prod.id
    subscription_id     = data.azurerm_client_config.current.subscription_id
  }

  provisioner "local-exec" {
    command = "az account management-group subscription add --management-group-id ${self.triggers.management_group_id} --subscription ${self.triggers.subscription_id}"
  }
}
#resource "azurerm_policy_definition" "location_restriction" {
#  name         = "restrict-resource-location"
#  policy_type  = "Custom"
#  mode         = "All"
#  display_name = "Restrict Resource Location"
#
#  policy_rule = jsonencode({
#    "if": {
#      "not": {
#        "field": "location",
#        "in": ["West Europe"]
#      }
#    },
#    "then": {
#      "effect": "deny"
#    }
#  })
#
#  metadata = jsonencode({
#    "version": "1.0.0",
#    "category": "General"
#  })
#}
#
#resource "azurerm_management_group_policy_assignment" "location_policy_assignment" {
#  management_group_id  = azurerm_management_group.prod.id
#  policy_definition_id = azurerm_policy_definition.location_restriction.id
#  name         = "Location"
#}