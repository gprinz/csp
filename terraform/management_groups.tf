#locals {
#  current_year      = formatdate("YYYY", timestamp())
#  start_of_year     = "${local.current_year}-01-01T00:00:00Z"
#  end_of_year       = "${local.current_year}-12-31T00:00:00Z"
#}
#
#resource "azurerm_management_group" "prod" {
#  display_name               = "Production"
#}
#
#resource "azurerm_management_group" "dev" {
#  display_name               = "Development"
#}
#
#resource "azurerm_management_group" "test" {
#  display_name               = "Testing"
#}

#resource "null_resource" "subscription_association" {
#  triggers = {
#    management_group_id = azurerm_management_group.prod.id
#    subscription_id     = azurerm_client_config.current
#  }
#
#  provisioner "local-exec" {
#    command = "az account management-group subscription add --management-group-id ${self.triggers.management_group_id} --subscription ${self.triggers.subscription_id}"
#  }
#}

#Budget Policy for Management Group
#resource "azurerm_consumption_budget_management_group" "example_budget" {
#  name               = "budget"
#  management_group_id = azurerm_management_group.prod.id
#  amount             = 200
#  time_grain         = "Monthly"
#
#  time_period{
#    start_date = local.start_of_year
#    end_date   = local.end_of_year
#  }
#
#    notification {
#    enabled   = true
#    threshold = 90.0
#    operator  = "EqualTo"
#
#    contact_emails = [
#      "raphaelprinz@outlook.com"
#    ]
#  }
#}

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