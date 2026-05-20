# Step-by-Step: Terraform App Registrations via Azure DevOps

This pipeline automates the creation and updating of **Azure AD App Registrations** using Terraform and a configuration-driven approach.

## Step 1. Create the Pipeline Service Principal
### Create the Azure DevOps Service Connection (OIDC)

## Step 2. Grant Required Permissions
```bash
SP_OBJECT_ID="<object-id-from-step-1>"

# 1. Assign Application Administrator role in Entra ID
az rest --method POST \
  --uri "https://graph.microsoft.com/v1.0/directoryRoles/roleTemplateId=9b895d92-2cd3-44c7-9d02-a6ac2d5ea5c3/members/\$ref" \
  --body "{\"@odata.id\": \"https://graph.microsoft.com/v1.0/directoryObjects/${SP_OBJECT_ID}\"}"

# 2. Grant Application.ReadWrite.All on Microsoft Graph
GRAPH_SP_ID=$(az ad sp list \
  --filter "appId eq '00000003-0000-0000-c000-000000000000'" \
  --query "[0].id" -o tsv)

APP_RW_ROLE_ID=$(az ad sp show \
  --id "00000003-0000-0000-c000-000000000000" \
  --query "appRoles[?value=='Application.ReadWrite.All'].id" -o tsv)

az rest --method POST \
  --uri "https://graph.microsoft.com/v1.0/servicePrincipals/${GRAPH_SP_ID}/appRoleAssignedTo" \
  --body "{
    \"principalId\": \"${SP_OBJECT_ID}\",
    \"resourceId\": \"${GRAPH_SP_ID}\",
    \"appRoleId\": \"${APP_RW_ROLE_ID}\"
  }"
  ```
  ## Step 3: Create Azure Storage for Terraform State
  ### Grant the SP Storage Blob Data Contributor on the storage account:
  ```bash
RESOURCE_GROUP="rg-terraform-state"
STORAGE_ACCOUNT="sttfstate$RANDOM"     # must be globally unique
CONTAINER="tfstate"
LOCATION="eastus"

# Create resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create storage account
az storage account create \
  --name $STORAGE_ACCOUNT \
  --resource-group $RESOURCE_GROUP \
  --location $LOCATION \
  --sku Standard_LRS

# Create container
az storage container create \
  --name $CONTAINER \
  --account-name $STORAGE_ACCOUNT

# Grant the pipeline SP access to the storage account
az role assignment create \
  --assignee <objectID of the app reg> \
  --role "Storage Blob Data Contributor" \
  --scope $(az storage account show \
    --name $STORAGE_ACCOUNT \
    --resource-group $RESOURCE_GROUP \
    --query id -o tsv)

echo "Storage Account: $STORAGE_ACCOUNT"   # save this
```
## Step 4: Create the Terraform Configuration
```bash
your-repo/
├── azure-pipelines.yml
└── terraform/
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    ├── backend.tf
```
### terraform/backend.tf
```bash
terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "<your-storage-account-name>"
    container_name       = "tfstate"
    key                  = "appreg.terraform.tfstate"
  }
}
```
### terraform/main.tf
```bash
terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
}

provider "azuread" {}

# App Registration
resource "azuread_application" "app" {
  display_name     = "${var.app_name}"
  sign_in_audience = "AzureADMyOrg"

  api {
    oauth2_permission_scope {
      admin_consent_description  = "Allow the app to access ${var.app_name} on behalf of the user"
      admin_consent_display_name = "Access ${var.app_name}"
      enabled                    = true
      id                         = var.oauth_scope_id
      type                       = "User"
      value                      = "user_impersonation"
    }
  }

  required_resource_access {
    resource_app_id = "00000003-0000-0000-c000-000000000000" # Microsoft Graph

    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
      type = "Scope"
    }
  }

  tags = ["environment:" "managed-by:terraform"]
}

# Service Principal
resource "azuread_service_principal" "app" {
  client_id = azuread_application.app.client_id
}

# Client Secret
resource "azuread_application_password" "app" {
  application_id = azuread_application.app.id
  display_name   = "pipeline-managed-secret"
  end_date       = timeadd(timestamp(), "8760h")  # 1 year

  lifecycle {
    ignore_changes = [end_date]                   # prevent recreation on every run
  }
}
```
### terraform/variables.tf
```bash
variable "app_name" {
  description = "Display name of the app registration"
  type        = string
  default     = "terraform-ironclaw"
}

variable "oauth_scope_id" {
  description = "UUID for the OAuth2 permission scope"
  type        = string
  default     = "00000000-0000-0000-0000-000000000001"
}
```
### terraform/outputs.tf
```bash
output "client_id" {
  description = "App registration client ID"
  value       = azuread_application.app.client_id
}

output "object_id" {
  description = "App registration object ID"
  value       = azuread_application.app.object_id
}

output "client_secret" {
  description = "App registration client secret"
  value       = azuread_application_password.app.value
  sensitive   = true
}
```
### terraform/environments/dev.tfvars
```bash
environment    = "dev"
app_name       = "myapp"
oauth_scope_id = "00000000-0000-0000-0000-000000000001"   # generate with uuidgen
```
## Step 5: Create Azure DevOps Variable Groups
### Pipelines → Library → Variable group → name: terraform-secrets

| Variable                   | Value                        | Secret |
|----------------------------|------------------------------|--------|
| ARM_CLIENT_ID              | appID                        | No     
| ARM_TENANT_ID              | tenantId                     | No     |
| ARM_SUBSCRIPTION_ID        | subscription ID              | No     |
| ARM_USE_OIDC               | true                         | No     |

## Step 6: Update the variables.tf for each individual app registration
```bash
variable "app_name" {
  description = "Display name of the app registration"
  type        = string
  default     = "terraform-ironclaw"
}

variable "oauth_scope_id" {
  description = "UUID for the OAuth2 permission scope"
  type        = string
  default     = "00000000-0000-0000-0000-000000000001"
}
```
## Step 7: Create and run the Pipeline