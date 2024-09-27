# Azure Data Platform

This project marks the completion of the **Diploma of Advanced Studies (DAS)** at ETH Zürich. It focuses on creating a data platform on **Microsoft Azure** using Infrastructure as Code (IaC), laying the foundation for future machine learning experiments with Azure’s managed feature store.

## Table of Contents

- [Project Overview](#project-overview)
- [Repository Structure](#repository-structure)
- [Setup Instructions](#setup-instructions)
  - [Initialize Git](#initialize-git)
  - [Set Up GitHub Actions (CI/CD Pipeline)](#set-up-github-actions-cicd-pipeline)
  - [Installing Pre-commit Hooks](#installing-pre-commit-hooks)
  - [Configure HashiCorp Cloud Platform (HCP)](#configure-hashicorp-cloud-platform-hcp)


## Project Overview

The project involves:

- **Azure Data Factory (ADF)** as the integration service to load big data from the internet into **Synapse Analytics**, Azure's integrated analytics service.
- **Synapse Analytics** for storing and managing big data.
- Creating a **Managed Feature Store** for machine learning experiments using Azure’s capabilities.

The platform enables loading, processing, and analyzing big data for future machine learning initiatives on Azure.

## Repository Structure

```text
+-- .github/
|   +-- workflows/
|   |   +-- deploy.yml      # CI/CD Pipeline for automated deployments

+-- arm/
|   +-- parameters.json     # ARM parameters
|   +-- template.json       # ARM templates for Azure resources

+-- managed_feature_store/  # Scripts related to setting up the managed feature store

+-- terraform/              
|   +-- data_factory.tf      # Terraform for Azure Data Factory
|   +-- main.tf              # Main Terraform configuration
|   +-- management_groups.tf # Terraform for Azure Management Groups
|   +-- synapse.tf           # Terraform for Synapse Analytics
|   +-- variables.tf         # Variables for Terraform deployment

+-- .pre-commit-config.yaml  # Pre-commit hooks configuration

+-- README.md                # Project documentation
```

## Setup Instructions

### Initialize Git

```bash
# Initialize the Git repository
git init

# Stage all files for the first commit
git add .

# Commit the changes with a message
git commit -m "Initial commit"

# Create the main branch
git branch -M main

# Add the remote repository URL
git remote add origin <repository-url>

# Push the changes to the remote repository
git push -u origin main
```

### Set Up GitHub Actions (CI/CD Pipeline)
To automate deployments, this project uses GitHub Actions. The CI/CD pipeline is defined in .github/workflows/deploy.yml.

To configure the pipeline:

1. Navigate to your GitHub repository settings and set the following Azure credentials as repository secrets:
    - `AZURE_CLIENT_ID`
    - `AZURE_CLIENT_SECRET`
    - `AZURE_TENANT_ID`
    - `AZURE_SUBSCRIPTION_ID`

2. Once these secrets are configured, any push to the main branch will trigger the pipeline to deploy the infrastructure automatically.

### Installing Pre-commit Hooks

This repository uses pre-commit hooks to ensure code quality and consistency before committing any changes.

To set up pre-commit:

```python
# Install the pre-commit package
pip install pre-commit

# Install the hooks defined in the .pre-commit-config.yaml file
pre-commit install

# To run the hooks manually on all files
pre-commit run --all-files
```
### Configure HashiCorp Cloud Platform (HCP)

1. Create an account on [HashiCorp Cloud Platform](https://cloud.hashicorp.com/) and set up a Terraform Cloud workspace.
   
2. Update the `terraform/main.tf` file with your **HCP credentials** and workspace information:

    ```hcl
    backend "remote" {
      organization = "your-organization"
    
      workspaces {
        name = "your-workspace"
      }
    }
    ```
    
3. Ensure that your Terraform Cloud workspace is set to use **remote execution** to handle your Terraform runs and state management.
