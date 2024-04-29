terraform {
  required_providers {
    azurerm = {
        source = "hashicorp/azurerm"
        version = "=2.46.0"
    }
  }
  #backend "azurerm" {
  #  resource_group_name = "tfstate"
  #  storage_account_name = "tfstate9802"
  #  container_name = "tfstate"
  #  key = "terraform.tfstate"
  #}
}

provider "azurerm" {
  features {}
  #subscription_id = "3e53b3eb-60c4-43ab-b236-bc0cef419fe2"
  #client_id       = "f7949458-7404-4c07-8ab8-1ecba7f70924"
  #client_secret   = "TWR8Q~JfIeEn5E3CfsAdTQVKZ.2FE8MSLoOw5bX3"
  #tenant_id       = "8732780d-dfeb-4c43-b551-b20e137b33cf"
  }

resource "azurerm_resource_group" "rg" {
    name = "store-rg"
    location = "East US"
}

resource "azurerm_storage_account" "stacc" {
    name                     = "devenstacc"
    resource_group_name      = azurerm_resource_group.rg.name
    location                 = azurerm_resource_group.rg.location
    account_tier            = "Standard"
    account_replication_type = "GRS"

    tags = {
        environment = "dev"
    }
}