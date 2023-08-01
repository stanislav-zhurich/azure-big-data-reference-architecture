terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.67.0"
    }
    databricks = {
      source = "databricks/databricks"
    }
    
    random = {
      source  = "hashicorp/random"
      version = "3.4.3"
    }
  }
}
