terraform {
  backend "remote" {
    organization = "CSP-ETH"
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
  name                     = "kv-${local.current_year}-ch"
  location                 = azurerm_resource_group.ml_rg.location
  resource_group_name      = azurerm_resource_group.ml_rg.name
  tenant_id                = data.azurerm_client_config.current.tenant_id
  sku_name                 = "premium"
  purge_protection_enabled = true
}

# Storage account configuration
resource "azurerm_storage_account" "storage" {
  name                     = "sa${local.current_year}ch"
  location                 = azurerm_resource_group.ml_rg.location
  resource_group_name      = azurerm_resource_group.ml_rg.name
  account_tier             = "Standard"
  account_replication_type = "GRS"
}

# Key Vault key
resource "azurerm_key_vault_key" "kv_key" {
  name         = "kv-key-${local.current_year}-ch"
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
    #azurerm_key_vault_access_policy.kv_access
  ]
}

# Machine learning workspace configuration
resource "azurerm_machine_learning_workspace" "ml_workspace" {
  name                    = "workspace-${local.current_year}-ch"
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