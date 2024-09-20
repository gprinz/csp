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

# Resource for Subscription Management Group Association
resource "azurerm_management_group_subscription_association" "subscription_mgmt_group_association" {
  management_group_id = azurerm_management_group.mg_production.id
  subscription_id     = "/subscriptions/${data.azurerm_client_config.current.subscription_id}"
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
