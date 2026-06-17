variable "team_name" {
  description = "Short name of the team (e.g. analytics, ingest). Used in resource names."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]{2,12}$", var.team_name))
    error_message = "team_name must be 2-12 lowercase alphanumeric characters."
  }
}

variable "environment" {
  description = "Deployment environment (dev, tst, prd)."
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "tst", "prd"], var.environment)
    error_message = "environment must be one of: dev, tst, prd."
  }
}

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "westeurope"
}

variable "aad_group_id" {
  description = "Object ID of the Azure AD group for this team."
  type        = string
}

variable "storage_replication" {
  description = "Storage account replication type."
  type        = string
  default     = "LRS"
}

variable "databricks_sku" {
  description = "Databricks workspace SKU (trial, standard, premium)."
  type        = string
  default     = "premium"
}
