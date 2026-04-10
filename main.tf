terraform {
  required_version = ">= 1.7.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
}

resource "random_string" "suffix" {
  length  = 6
  lower   = true
  upper   = false
  numeric = true
  special = false
}

locals {
  //Names
  resource_group_name              = "${var.resource_group_name}-${random_string.suffix.result}"
  static_web_app_name              = "${var.static_web_app_name}${random_string.suffix.result}"
  communication_service_name       = "${var.communication_service_name}${random_string.suffix.result}"
  email_communication_service_name = "${var.email_communication_service_name}${random_string.suffix.result}"
  api_management_name              = "${var.api_management_name}${random_string.suffix.result}"
  log_analytics_workspace_name     = "${var.log_analytics_workspace_name}${random_string.suffix.result}"
  application_insights_name        = "${var.application_insights_name}${random_string.suffix.result}"
  service_plan_name                = "${var.service_plan_name}${random_string.suffix.result}"
  function_app_name                = "${var.function_app_name}${random_string.suffix.result}"
  function_storage_account_name    = substr("funcsa${random_string.suffix.result}", 0, 24)
  storage_account_name             = substr("${var.storage_account_name}${random_string.suffix.result}", 0, 24)

  //Function
  function_host_key                = data.azurerm_function_app_host_keys.functionAppHostKeys.default_function_key

  //Sender Email address
  sender_email_address             = "DoNotReply@${azurerm_email_communication_service_domain.emailCommunicationServiceDomain.from_sender_domain}"
}

//Resource group
resource "azurerm_resource_group" "resourceGroup" {
  name     = local.resource_group_name
  location = var.location
}

//Static web app
resource "azurerm_static_web_app" "staticwebapp" {
  name                = local.static_web_app_name
  resource_group_name = azurerm_resource_group.resourceGroup.name
  location            = azurerm_resource_group.resourceGroup.location
}

//Communication services
resource "azurerm_communication_service" "communicationService" {
  name                = local.communication_service_name
  resource_group_name = azurerm_resource_group.resourceGroup.name
  data_location       = "Europe"
}

resource "azurerm_email_communication_service" "emailCommunicationService" {
  name                = local.email_communication_service_name
  resource_group_name = azurerm_resource_group.resourceGroup.name
  data_location       = "Europe"
}

resource "azurerm_email_communication_service_domain" "emailCommunicationServiceDomain" {
  name             = "AzureManagedDomain"
  email_service_id = azurerm_email_communication_service.emailCommunicationService.id

  domain_management = "AzureManaged"
}
//Storage account and table
resource "azurerm_storage_account" "storageAccount" {
  name                     = local.storage_account_name
  resource_group_name      = azurerm_resource_group.resourceGroup.name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_table" "storageAccountTable" {
  name                 = "ScheduledEmails"
  storage_account_name = azurerm_storage_account.storageAccount.name
}

//Monitoring
resource "azurerm_log_analytics_workspace" "logAnalyticsWorkspace" {
  name                = local.log_analytics_workspace_name
  location            = azurerm_resource_group.resourceGroup.location
  resource_group_name = azurerm_resource_group.resourceGroup.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_application_insights" "applicationInsights" {
  name                = local.application_insights_name
  location            = azurerm_resource_group.resourceGroup.location
  resource_group_name = azurerm_resource_group.resourceGroup.name
  application_type    = "web"
  workspace_id        = azurerm_log_analytics_workspace.logAnalyticsWorkspace.id
}

//Functions app
resource "azurerm_storage_account" "functionStorageAccount" {
  name                     = local.function_storage_account_name
  resource_group_name      = azurerm_resource_group.resourceGroup.name
  location                 = azurerm_resource_group.resourceGroup.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "functionStorageContainer" {
  name                  = "functionstoragecontainer"
  storage_account_id    = azurerm_storage_account.functionStorageAccount.id
  container_access_type = "private"
}

resource "azurerm_service_plan" "functionServicePlan" {
  name                = local.service_plan_name
  resource_group_name = azurerm_resource_group.resourceGroup.name
  location            = azurerm_resource_group.resourceGroup.location
  sku_name            = "FC1"
  os_type             = "Linux"
}

resource "azurerm_function_app_flex_consumption" "functionApp" {
  name                = local.function_app_name
  resource_group_name = azurerm_resource_group.resourceGroup.name
  location            = azurerm_resource_group.resourceGroup.location
  service_plan_id     = azurerm_service_plan.functionServicePlan.id

  storage_container_type      = "blobContainer"
  storage_container_endpoint  = "${azurerm_storage_account.functionStorageAccount.primary_blob_endpoint}${azurerm_storage_container.functionStorageContainer.name}"
  storage_authentication_type = "StorageAccountConnectionString"
  storage_access_key          = azurerm_storage_account.functionStorageAccount.primary_access_key

  runtime_name    = "dotnet-isolated"
  runtime_version = "10.0"

  maximum_instance_count      = 50
  instance_memory_in_mb       = 2048

  app_settings = {
    "AcsEmailSender"                        = local.sender_email_address
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.applicationInsights.connection_string
    "APPINSIGHTS_INSTRUMENTATIONKEY"        = azurerm_application_insights.applicationInsights.instrumentation_key
    "CommunicationServicesConnectionString" = azurerm_communication_service.communicationService.primary_connection_string
    "ScheduledEmailsStorageConnectionString" = azurerm_storage_account.storageAccount.primary_connection_string
  }

  site_config {}
}

data "azurerm_function_app_host_keys" "functionAppHostKeys" {
  name                = azurerm_function_app_flex_consumption.functionApp.name
  resource_group_name = azurerm_resource_group.resourceGroup.name
}

//API management
resource "azurerm_api_management" "apiManagement" {
  name                = local.api_management_name
  location            = azurerm_resource_group.resourceGroup.location
  resource_group_name = azurerm_resource_group.resourceGroup.name
  publisher_name      = var.api_management_publisher_name
  publisher_email     = var.api_management_publisher_email

  sku_name = "Consumption_0"
}

resource "azurerm_api_management_named_value" "functionKey" {
  name                = "future-me-key"
  api_management_name = azurerm_api_management.apiManagement.name
  resource_group_name = azurerm_resource_group.resourceGroup.name
  display_name        = "future-me-key"
  value               = local.function_host_key
  secret              = true
}

resource "azurerm_api_management_api" "apiManagementApi" {
  name                = "future-me-api"
  resource_group_name = azurerm_resource_group.resourceGroup.name
  api_management_name = azurerm_api_management.apiManagement.name
  revision            = "1"
  display_name        = "future-me"
  protocols           = ["https"]
  service_url         = "https://${azurerm_function_app_flex_consumption.functionApp.default_hostname}/ScheduleEmail"
  subscription_required = false
}

resource "azurerm_api_management_api_operation" "apiManagementOperation" {
  operation_id        = "apiManagementOperation"
  api_name            = azurerm_api_management_api.apiManagementApi.name
  api_management_name = azurerm_api_management.apiManagement.name
  resource_group_name = azurerm_resource_group.resourceGroup.name
  display_name        = "POST"
  method              = "POST"
  url_template        = "/ScheduleEmail"
}

resource "azurerm_api_management_api_operation_policy" "apiManagementOperationPolicy" {
  api_name            = azurerm_api_management_api_operation.apiManagementOperation.api_name
  api_management_name = azurerm_api_management_api_operation.apiManagementOperation.api_management_name
  resource_group_name = azurerm_api_management_api_operation.apiManagementOperation.resource_group_name
  operation_id        = azurerm_api_management_api_operation.apiManagementOperation.operation_id

  depends_on = [
    azurerm_api_management_named_value.functionKey
  ]

  xml_content = file("${path.module}/apimpolicies.xml")
}
