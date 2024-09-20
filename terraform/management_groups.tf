# Management Group for Production
resource "azurerm_management_group" "mg_production" {
  display_name = "Production"
}

# Management Group for Development
resource "azurerm_management_group" "mg_development" {
  display_name = "Development"
}

# Management Group for Testing
resource "azurerm_management_group" "mg_testing" {
  display_name = "Testing"
}

# Associate Subscription with Production Management Group
resource "null_resource" "subscription_mgmt_group_association" {
  triggers = {
    management_group_id = azurerm_management_group.mg_production.id
    subscription_id     = data.azurerm_client_config.current.subscription_id
  }

  provisioner "local-exec" {
    command = "az account management-group subscription add --management-group-id ${self.triggers.management_group_id} --subscription ${self.triggers.subscription_id}"
  }
}

# Custom Policy Definition for Location Restriction
resource "azurerm_policy_definition" "location_restriction_policy" {
  name         = "restrict-resource-location"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Restrict Resource Location"

  policy_rule = jsonencode({
    "if" : {
      "not" : {
        "field" : "location",
        "in" : ["West Europe"]
      }
    },
    "then" : {
      "effect" : "deny"
    }
  })

  metadata = jsonencode({
    "version" : "1.0.0",
    "category" : "General"
  })
}
