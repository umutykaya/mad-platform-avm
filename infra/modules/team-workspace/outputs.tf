output "resource_group_name" {
  description = "Name of the team Resource Group."
  value       = module.resource_group.name
}

output "databricks_workspace_url" {
  description = "URL of the Databricks workspace."
  value       = module.databricks_workspace.databricks_workspace_url
}

output "databricks_workspace_id" {
  description = "Azure resource ID of the Databricks workspace."
  value       = module.databricks_workspace.databricks_id
}

output "storage_account_name" {
  description = "Name of the team storage account."
  value       = module.storage.name
}

output "storage_container_name" {
  description = "Name of the primary data container."
  value       = azurerm_storage_container.team_data.name
}

output "managed_identity_client_id" {
  description = "Client ID of the team Managed Identity (use in Databricks cluster config)."
  value       = azurerm_user_assigned_identity.team.client_id
}
