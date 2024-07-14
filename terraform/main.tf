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
    "Recover", # Add this line
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
