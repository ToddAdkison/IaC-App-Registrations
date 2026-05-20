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