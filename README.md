# Future Me Infrastructure

Terraform configuration for provisioning the Azure infrastructure used by Future Me.

## What This Deploys

This project creates:

- An Azure Resource Group
- An Azure Static Web App
- Azure Communication Services and an Email Communication Service
- A Storage Account with a `ScheduledEmails` table
- A Log Analytics Workspace and Application Insights
- A Linux Flex Consumption Azure Function App
- Azure API Management in the Consumption tier

API Management is configured to forward requests to the Function App and applies a policy from [`apimpolicies.xml`](./apimpolicies.xml). The allowed CORS origin is sourced from the deployed Static Web App hostname.

## Prerequisites

- Terraform `>= 1.7.0`
- An Azure subscription
- Permission to create Azure resources in that subscription
- Azure authentication already configured locally, for example with Azure CLI

## Required Input

The only required variable is the Azure subscription ID.

Example `terraform.tfvars`:

```
hcl
subscription_id = "00000000-0000-0000-0000-000000000000"
```

## Usage

Initialize the working directory:

```powershell
terraform init
```

Review the execution plan:

```powershell
terraform plan
```

Apply the infrastructure:

```powershell
terraform apply
```

## Outputs

After apply, Terraform returns:

- Resource group name
- Function App name
- Application Insights name

## Notes

- Resource names are suffixed with a random string to avoid naming collisions.
- After deployment, the Static Web App and Function App must still be connected to a repository that contains the application code.