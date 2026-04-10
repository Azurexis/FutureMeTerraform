//Subscription
variable "subscription_id" {
  type        = string
  description = "Azure subscription ID."
}

//Resource Group
variable "resource_group_name" {
  type        = string
  description = "Name of the resource group."
  default     = "rg-futureme-dev"
}

variable "location" {
  type        = string
  description = "Azure Region."
  default     = "westeurope"
}

//Static web app
variable "static_web_app_name" {
  type        = string
  description = "Name of the static web app account."
  default     = "staticwebappfuturemedev"
}

//Communication services
variable "communication_service_name" {
  type        = string
  description = "Name of the communication service."
  default     = "csfuturemedev"
}

variable "email_communication_service_name" {
  type        = string
  description = "Name of the email communication service."
  default     = "ecsfuturemedev"
}

//Storage account
variable "storage_account_name" {
  type        = string
  description = "Name of the storage account."
  default     = "safuturemedev"
}

//Functions app
variable "service_plan_name" {
  type        = string
  description = "Name of the App Service plan for the function app."
  default     = "spfunctionapp"
}

variable "function_app_name" {
  type        = string
  description = "Name of the function app."
  default     = "fafuturemedev"
}

//API Management
variable "api_management_name" {
  type        = string
  description = "Name of the API management."
  default     = "apimfuturemedev"
}

variable "api_management_publisher_name" {
  type        = string
  description = "Name of the publisher of the API management."
  default     = "Publisher Name"
}

variable "api_management_publisher_email" {
  type        = string
  description = "EMail of the publisher of the API management."
  default     = "company@terraform.io"
}

//Monitoring
variable "log_analytics_workspace_name" {
  type        = string
  description = "Name of the Log Analytics workspace."
  default     = "lawfuturemedev"
}

variable "application_insights_name" {
  type        = string
  description = "Name of the Application Insights instance."
  default     = "aifuturemedev"
}