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