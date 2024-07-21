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
      recover_soft_deleted_keys    = true
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
  name                     = "kv-${local.current_year}-ch100"
  location                 = azurerm_resource_group.ml_rg.location
  resource_group_name      = azurerm_resource_group.ml_rg.name
  tenant_id                = data.azurerm_client_config.current.tenant_id
  sku_name                 = "premium"
  purge_protection_enabled = false
}

# Storage account configuration
resource "azurerm_storage_account" "ml" {
  name                     = "saml${local.current_year}ch"
  location                 = azurerm_resource_group.ml_rg.location
  resource_group_name      = azurerm_resource_group.ml_rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Storage account configuration
resource "azurerm_storage_account" "raw_data" {
  name                     = "data${local.current_year}ch"
  location                 = azurerm_resource_group.rg_prod.location
  resource_group_name      = azurerm_resource_group.rg_prod.name
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Storage Container named raw-data
resource "azurerm_storage_container" "raw_data" {
  name                  = "raw-data"
  storage_account_name  = azurerm_storage_account.raw_data.name
  container_access_type = "private"
}

// Define a container called "taxi" in the Azure Storage Account
resource "azurerm_storage_container" "taxi" {
  name                  = "taxi"
  storage_account_name  = azurerm_storage_account.datalake.name
  container_access_type = "private"
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

# Key Vault key
resource "azurerm_key_vault_key" "kv_key" {
  name                = "kv-key-${local.current_year}ch"
  key_vault_id        = azurerm_key_vault.kv.id
  key_type            = "RSA"
  key_size            = 2048
  soft_delete_enabled = true

  key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey"
  ]

  depends_on = [
    azurerm_key_vault.kv,
    azurerm_key_vault_access_policy.kv_access
  ]
}

# Machine learning workspace configuration
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

  encryption {
    key_vault_id = azurerm_key_vault.kv.id
    key_id       = azurerm_key_vault_key.kv_key.id
  }
}

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

  encryption {
    key_vault_id = azurerm_key_vault.kv.id
    key_id       = azurerm_key_vault_key.kv_key.id
  }
}