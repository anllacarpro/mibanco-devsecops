terraform {
  backend "azurerm" {
    resource_group_name  = "mibanco-devsecops-tfstate"
    storage_account_name = "mibancotfstate12345"
    container_name       = "tfstate"
    key                  = "terraform.tfstate"
  }
}
