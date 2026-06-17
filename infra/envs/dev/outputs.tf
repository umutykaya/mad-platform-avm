output "analytics_workspace_url" {
  value = module.analytics.databricks_workspace_url
}

output "ingest_workspace_url" {
  value = module.ingest.databricks_workspace_url
}

output "analytics_storage" {
  value = module.analytics.storage_account_name
}

output "ingest_storage" {
  value = module.ingest.storage_account_name
}
