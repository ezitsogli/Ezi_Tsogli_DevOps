
locals {
  tags = {
    owner       = var.tag_department
    region      = var.tag_region
    environment = var.environment
  }
}

// Existing Resources

/// Subscription ID

data "azurerm_subscription" "current" {
}

data "azurerm_client_config" "current" {}
// Random Suffix Generator

resource "random_integer" "deployment_id_suffix" {
  min = 100
  max = 999
}

// Resource Group

resource "azurerm_resource_group" "rg" {
  name     = "${var.class_name}-${var.student_name}-${var.environment}-${random_integer.deployment_id_suffix.result}-rg"
  location = var.location

  tags = local.tags
}


// Storage Account

resource "azurerm_storage_account" "storage" {
  name                     = "${var.class_name}${var.student_name}${var.environment}${random_integer.deployment_id_suffix.result}st"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  tags                     = local.tags
}

resource "azurerm_application_insights" "ai" {
  name                = "${var.class_name}-${var.student_name}-${var.environment}-${random_integer.deployment_id_suffix.result}-ai"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
}

resource "azurerm_key_vault" "keyvault" {
  name                = "${var.class_name}${var.student_name}${random_integer.deployment_id_suffix.result}kv"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "premium"
}

resource "azurerm_machine_learning_workspace" "mlw" {
  name                    = "${var.class_name}-${var.student_name}-${var.environment}-${random_integer.deployment_id_suffix.result}-mlw"
  location                = azurerm_resource_group.rg.location
  resource_group_name     = azurerm_resource_group.rg.name
  storage_account_id      = azurerm_storage_account.storage.id
  application_insights_id = azurerm_application_insights.ai.id
  key_vault_id            = azurerm_key_vault.keyvault.id

  tags = local.tags

  identity {
    type = "SystemAssigned"
  }
}



// Cosmos DB


resource "azurerm_cosmosdb_account" "db" {
  name                = "${var.class_name}-${var.student_name}-${var.environment}-${random_integer.deployment_id_suffix.result}-cosmos"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  offer_type          = "Standard"
  kind                = "MongoDB"

  enable_automatic_failover = true

  capabilities {
    name = "EnableAggregationPipeline"
  }

  capabilities {
    name = "mongoEnableDocLevelTTL"
  }

  capabilities {
    name = "MongoDBv3.4"
  }

  capabilities {
    name = "EnableMongo"
  }

  consistency_policy {
    consistency_level       = "BoundedStaleness"
    max_interval_in_seconds = 300
    max_staleness_prefix    = 100000
  }

  geo_location {
    location          = "eastus"
    failover_priority = 1
  }

  geo_location {
    location          = "westus"
    failover_priority = 0
  }

  tags = local.tags
}


//  Azure functions



resource "azurerm_app_service_plan" "asp" {
  name                = "${var.class_name}-${var.student_name}-${var.environment}-${random_integer.deployment_id_suffix.result}-asp"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_function_app" "func" {
  name                       = "${var.class_name}-${var.student_name}-${var.environment}-${random_integer.deployment_id_suffix.result}-func"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  app_service_plan_id        = azurerm_app_service_plan.asp.id
  storage_account_name       = azurerm_storage_account.storage.name
  storage_account_access_key = azurerm_storage_account.storage.primary_access_key
}

// Virtual desk


resource "azurerm_virtual_desktop_workspace" "vdws" {
  name                = "${var.class_name}-${var.student_name}-${var.environment}-${random_integer.deployment_id_suffix.result}-vdws"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  friendly_name = "FriendlyName"
  description   = "A description of my workspace"
}