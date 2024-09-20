terraform {
  backend "remote" {
    organization = "CSP-ETH"
    workspaces {
      name = "PROD"
    }
  }

  required_providers {
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = ">= 0.1.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = false
      recover_soft_deleted_keys    = true
    }
  }
}

# Get Subscription ID and current year
data "azurerm_client_config" "current" {}
data "azurerm_subscription" "primary" {}

data "external" "current_year" {
  program = ["sh", "-c", "echo {\\\"year\\\":\\\"$(date +%Y)\\\"}"]
}

locals {
  current_year = data.external.current_year.result["year"]
}

# Resource Group for production
resource "azurerm_resource_group" "rg_prod" {
  name     = "rg-${local.current_year}-ch"
  location = "West Europe"
}

# Resource Group for machine learning
resource "azurerm_resource_group" "ml_rg" {
  name     = "rg-ml-${local.current_year}-ch"
  location = "West Europe"
}

# Application Insights configuration
resource "azurerm_application_insights" "ai" {
  name                = "ai-${local.current_year}-ch"
  location            = azurerm_resource_group.ml_rg.location
  resource_group_name = azurerm_resource_group.ml_rg.name
  application_type    = "web"
}

# Key Vault configuration
resource "azurerm_key_vault" "kv" {
  name                     = "kv-${local.current_year}-ch1200"
  location                 = azurerm_resource_group.ml_rg.location
  resource_group_name      = azurerm_resource_group.ml_rg.name
  tenant_id                = data.azurerm_client_config.current.tenant_id
  sku_name                 = "premium"
  purge_protection_enabled = true
}

# Storage account configuration
resource "azurerm_storage_account" "ml" {
  name                     = "saml${local.current_year}ch"
  location                 = azurerm_resource_group.ml_rg.location
  resource_group_name      = azurerm_resource_group.ml_rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
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
    "Recover"
  ]
}

# Machine Learning Workspace (Feature Store) configuration
resource "azurerm_machine_learning_workspace" "fstore" {
  name                    = "fstore-${local.current_year}-ch"
  location                = azurerm_resource_group.ml_rg.location
  resource_group_name     = azurerm_resource_group.ml_rg.name
  application_insights_id = azurerm_application_insights.ai.id
  key_vault_id            = azurerm_key_vault.kv.id
  storage_account_id      = azurerm_storage_account.ml.id
  kind                    = "FeatureStore"
  high_business_impact    = true

  feature_store {
    computer_spark_runtime_version = "3.1"
  }

  identity {
    type = "SystemAssigned"
  }
}

# Machine Learning Workspace configuration
resource "azurerm_machine_learning_workspace" "ml_workspace" {
  name                    = "workspace-${local.current_year}-ch"
  location                = azurerm_resource_group.ml_rg.location
  resource_group_name     = azurerm_resource_group.ml_rg.name
  application_insights_id = azurerm_application_insights.ai.id
  key_vault_id            = azurerm_key_vault.kv.id
  storage_account_id      = azurerm_storage_account.ml.id
  high_business_impact    = true

  identity {
    type = "SystemAssigned"
  }
}

# Role assignment for all managed identities (Contributor role at subscription level)
resource "azurerm_role_assignment" "fstore_contributor" {
  principal_id         = azurerm_machine_learning_workspace.fstore.identity[0].principal_id
  role_definition_name = "Contributor"
  scope                = data.azurerm_subscription.primary.id
}

resource "azurerm_role_assignment" "ml_workspace_contributor" {
  principal_id         = azurerm_machine_learning_workspace.ml_workspace.identity[0].principal_id
  role_definition_name = "Contributor"
  scope                = data.azurerm_subscription.primary.id
}