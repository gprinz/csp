resource "azuread_application" "sp" {
  display_name = "ml-devops-sp"
}

resource "azuread_service_principal" "sp" {
  client_id = azuread_application.sp.client_id
}

resource "azuread_service_principal_password" "sp_password" {
  service_principal_id = azuread_service_principal.sp.id
  value                = "P@ssword123!"
  end_date_relative    = "240h"
}

data "azurerm_subscription" "primary" {
}

resource "azurerm_role_assignment" "sp_role_assignment" {
  principal_id         = azuread_service_principal.sp.id
  role_definition_name = "Contributor"
  scope                = azurerm_subscription.primary.id
}

provider "azuredevops" {
  org_service_url       = "https://dev.azure.com/<your-organization>"
  personal_access_token = var.azure_devops_pat
}

resource "azuredevops_serviceendpoint_azurerm" "service_connection" {
  project_id            = azuredevops_project.project.id
  service_endpoint_name = "AzureMLServiceConnection"
  description           = "Connection to Azure ML Workspace"
  credentials {
    serviceprincipalid  = azuread_service_principal.sp.application_id
    serviceprincipalkey = azuread_service_principal_password.sp_password.value
    tenantid            = data.azurerm_client_config.example.tenant_id
  }
  resource_id = azurerm_machine_learning_workspace.aml_workspace.id
}

resource "azuredevops_project" "project" {
  name       = "MLProject"
  visibility = "private"
}

resource "azuredevops_git_repository" "repo" {
  project_id = azuredevops_project.project.id
  name       = "MLRepo"
  initialization {
    init_type   = "Clean"
    template_id = ""
  }
}

resource "azuredevops_build_definition" "pipeline" {
  project_id = azuredevops_project.project.id
  name       = "MLPipeline"
  path       = "\\"
  repository {
    repo_type   = "TfsGit"
    repo_id     = azuredevops_git_repository.repo.id
    branch_name = "main"
    yml_path    = "azure-pipelines.yml"
  }
  ci_trigger {
    use_yaml = true
  }
}