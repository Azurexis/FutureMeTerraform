output "resource_group_name" {
  value = azurerm_resource_group.resourceGroup.name
}

output "function_app_name" {
  value = azurerm_function_app_flex_consumption.functionApp.name
}

output "application_insights_name" {
  value = azurerm_application_insights.applicationInsights.name
}
