terraform {
  backend "azurerm" {
    resource_group_name  = "rg-terraform-state"
    storage_account_name = "sttfstate18957"
    container_name       = "tfstate"
    key                  = "appreg.terraform.tfstate"
  }
}