terraform {
  backend "remote" {
    organization = "csp"
    workspaces {
      name = "PROD"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
    }
  }
}

# Get Subscription ID
data "azurerm_client_config" "current" {}

locals {
  current_year      = formatdate("YYYY", timestamp())
  start_of_year     = "${local.current_year}-01-01T00:00:00Z"
  end_of_year       = "${local.current_year}-12-31T00:00:00Z"
}

resource "azurerm_management_group" "prod" {
  display_name               = "Production"
}

resource "azurerm_management_group" "dev" {
  display_name               = "Development"
}

resource "azurerm_management_group" "test" {
  display_name               = "Testing"
}

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
resource "azurerm_consumption_budget_management_group" "example_budget" {
  name               = "budget"
  management_group_id = azurerm_management_group.prod.id
  amount             = 200
  time_grain         = "Monthly"

  time_period{
    start_date = local.start_of_year
    end_date   = local.end_of_year
  }

    notification {
    enabled   = true
    threshold = 90.0
    operator  = "EqualTo"

    contact_emails = [
      "raphaelprinz@outlook.com"
    ]
  }
}

resource "azurerm_policy_definition" "location_restriction" {
  name         = "restrict-resource-location"
  policy_type  = "Custom"
  mode         = "All"
  display_name = "Restrict Resource Location"

  policy_rule = jsonencode({
    "if": {
      "not": {
        "field": "location",
        "in": ["West Europe"]
      }
    },
    "then": {
      "effect": "deny"
    }
  })

  metadata = jsonencode({
    "version": "1.0.0",
    "category": "General"
  })
}

resource "azurerm_management_group_policy_assignment" "location_policy_assignment" {
  management_group_id  = azurerm_management_group.prod.id
  policy_definition_id = azurerm_policy_definition.location_restriction.id
  name         = "Location"
}


























# Generate a random identifier
resource "random_id" "id" {
  byte_length = 4
}

# Resource Group for production
resource "azurerm_resource_group" "rg_prod" {
  name     = "rg-${random_id.id.hex}"
  location = "West Europe"
}

# Resource Group for machine learning
resource "azurerm_resource_group" "ml_rg" {
  name     = "rg-ml-${random_id.id.hex}"
  location = "West Europe"
}

# Application Insights configuration
resource "azurerm_application_insights" "ai" {
  name                = "ai-${random_id.id.hex}"
  location            = azurerm_resource_group.ml_rg.location
  resource_group_name = azurerm_resource_group.ml_rg.name
  application_type    = "web"
}

# Key Vault configuration
resource "azurerm_key_vault" "kv" {
  name                = "kv-${random_id.id.hex}"
  location            = azurerm_resource_group.ml_rg.location
  resource_group_name = azurerm_resource_group.ml_rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "premium"
  purge_protection_enabled = true
}

# Key Vault access policy
resource "azurerm_key_vault_access_policy" "kv_access" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Create",
    "Get",
    "Delete",
    "Purge",
    "GetRotationPolicy",
  ]
}

# Storage account configuration
resource "azurerm_storage_account" "storage" {
  name                     = "sa${random_id.id.hex}"
  location                 = azurerm_resource_group.ml_rg.location
  resource_group_name      = azurerm_resource_group.ml_rg.name
  account_tier             = "Standard"
  account_replication_type = "GRS"
}

# Key Vault key
resource "azurerm_key_vault_key" "kv_key" {
  name         = "kv-key-${random_id.id.hex}"
  key_vault_id = azurerm_key_vault.kv.id
  key_type     = "RSA"
  key_size     = 2048

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey",
  ]

  depends_on = [
    azurerm_key_vault.kv,
    azurerm_key_vault_access_policy.kv_access
  ]
}

# Machine learning workspace configuration
resource "azurerm_machine_learning_workspace" "ml_workspace" {
  name                    = "workspace-${random_id.id.hex}"
  location                = azurerm_resource_group.ml_rg.location
  resource_group_name     = azurerm_resource_group.ml_rg.name
  application_insights_id = azurerm_application_insights.ai.id
  key_vault_id            = azurerm_key_vault.kv.id
  storage_account_id      = azurerm_storage_account.storage.id
  kind                    = "FeatureStore"

  feature_store {
    computer_spark_runtime_version = "3.1"
  }

  identity {
    type = "SystemAssigned"
  }

  encryption {
    key_vault_id = azurerm_key_vault.kv.id
    key_id       = azurerm_key_vault_key.kv_key.id
  }
}

# Machine learning workspace configuration
resource "azurerm_machine_learning_workspace" "ml_workspace_ds" {
  name                    = "workspace-ds${random_id.id.hex}"
  location                = azurerm_resource_group.ml_rg.location
  resource_group_name     = azurerm_resource_group.ml_rg.name
  application_insights_id = azurerm_application_insights.ai.id
  key_vault_id            = azurerm_key_vault.kv.id
  storage_account_id      = azurerm_storage_account.storage.id

  identity {
    type = "SystemAssigned"
  }

  encryption {
    key_vault_id = azurerm_key_vault.kv.id
    key_id       = azurerm_key_vault_key.kv_key.id
  }
}
