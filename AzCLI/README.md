# Azure DevOps - App Registration Deployment

This pipeline automates the creation and updating of **Azure AD App Registrations** using Azure CLI and a configuration-driven approach.

## Features

- Idempotent (Create or Update)
- Configurable via YAML file stored in Git
- Supports Redirect URIs and API Permissions
- Easy to manage multiple environments

## 1. Basic Usage (Simple Example)
```yaml
appDisplayName: "My Web App"
signInAudience: "AzureADMyOrg"
redirectUris: "https://localhost:4200"
apiPermissions: "User.Read openid"
```
---
## 2. Example With Multiple Redirect URIs
```yaml
appDisplayName: "My Production Web App"
signInAudience: "AzureADMyOrg"
redirectUris: "https://localhost:4200 https://myapp.company.com/signin-oidc https://myapp.azurewebsites.net/signin-oidc"
apiPermissions: "User.Read openid profile offline_access"
```
---
## 3. Example with Multiple Redirect URIs and API permissions
```yaml
appDisplayName: "Customer Portal - Production"
signInAudience: "AzureADMultipleOrgs"
redirectUris:
  https://portal.company.com/signin-oidc
  https://localhost:3000
  https://staging-portal.company.com/signin-oidc
apiPermissions: "User.Read openid profile offline_access Directory.Read.All"
```
## Configuration Reference
| Parameter        | Description                                 | Example                                      |
|------------------|---------------------------------------------|----------------------------------------------|
| appDisplayName   | Name of the App Registration                | "My Application - Prod"                      |
| signInAudience   | Who can use the application                 | AzureADMyOrg, AzureADMultipleOrgs            |
| redirectUris     | Space-separated redirect URIs               | https://localhost https://myapp.com          |
| apiPermissions   | Space-separated Microsoft Graph permissions | User.Read openid profile                     |


## How to Run the Pipeline
1. Go to your pipeline in Azure DevOps.
2. Click Run pipeline.
3. Set the parameter:
    * Config File Path: app-config.yml (default) or any other config file.
4. Click Run.

