terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
  }
}

provider "azuread" {
  use_oidc = true          # ← OIDC instead of client secret
}

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
    resource_app_id = "00000003-0000-0000-c000-000000000000"

    resource_access {
      id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d" # User.Read
      type = "Scope"
    }
  }

  tags = ["environment: managed-by:terraform"]
}

resource "azuread_service_principal" "app" {
  client_id = azuread_application.app.client_id
}

resource "azuread_application_password" "app" {
  application_id = azuread_application.app.id
  display_name   = "pipeline-managed-secret"
  end_date       = timeadd(timestamp(), "8760h")

  lifecycle {
    ignore_changes = [end_date]
  }
}