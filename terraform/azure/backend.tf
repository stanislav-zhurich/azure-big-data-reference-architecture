terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.67.0"
    }
    databricks = {
      source = "databricks/databricks"
      version = "1.3.0"
    }
    
    random = {
      source  = "hashicorp/random"
      version = "3.4.3"
    }
    
  }
}
