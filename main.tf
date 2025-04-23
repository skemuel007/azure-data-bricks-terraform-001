terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"  # or latest version
    }
  }
}

# Configure the Azure Provider
provider "azurerm" {
  features {}
}

# Define variables
variable "resource_group_name" {
  type    = string
  default = "nex-uda-dev-euw-rg"
}

variable "location" {
  type    = string
  default = "West Europe"
}

variable "storage_account_name" {
  type    = string
  default = "nexudadeveuwst" #Must be globally unique
}

variable "databricks_name" {
  type    = string
  default = "nexuddeveuwadb"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "project" {
  type    = string
  default = "uda"
}

variable "container_names" {
  type    = list(string)
  default = ["bronze", "silver", "gold", "work-labs"]  # List of container names
}

# Create Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

# Create Data Bricks
resource "azurerm_databricks_workspace" "databricks" {
  name                = var.databricks_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "trial"  # "standard" or "premium" or "trial"

  # optional tags
  tags = {
    environment = var.environment
    project     = var.project
  }
}

# Create Storage Account (ADLS Gen2)
resource "azurerm_storage_account" "adls" {
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  is_hns_enabled           = true
  access_tier              = "Hot"

  tags = {
    environment = var.environment
    project     = var.project
  }
}

# Create Storage Containers
resource "azurerm_storage_container" "containers" {
  for_each              = toset(var.container_names)
  name                  = each.value
  storage_account_name  = azurerm_storage_account.adls.name
  container_access_type = "private"
}

# Output the Storage Account Name
output "storage_account_name" {
  value = azurerm_storage_account.adls.name
}

# Output the Storage Container Names
output "container_names" {
  value = var.container_names
}

# Output the Databricks Workspace URL
output "databricks_workspace_url" {
  value = azurerm_databricks_workspace.databricks.workspace_url
}
