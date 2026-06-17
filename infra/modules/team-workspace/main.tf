# ---------------------------------------------------------------------------
# MAD – team-workspace module
# Provisions one complete team slice: Resource Group, Storage, Databricks
# workspace, Managed Identity, and RBAC assignments.
#
# Uses Azure Verified Modules (AVM) where available:
#   - Azure/avm-res-resources-resourcegroup
#   - Azure/avm-res-storage-storageaccount
#   - Azure/avm-res-databricks-workspace
# ---------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110"
    }
    databricks = {
      source  = "databricks/databricks"
      version = "~> 1.40"
    }
  }
}

# ---------------------------------------------------------------------------
# Resource Group  (AVM)
# ---------------------------------------------------------------------------
module "resource_group" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.1.0"

  name     = "rg-mad-${var.team_name}-${var.environment}"
  location = var.location

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# User-Assigned Managed Identity
# ---------------------------------------------------------------------------
resource "azurerm_user_assigned_identity" "team" {
  name                = "mi-mad-${var.team_name}-${var.environment}"
  location            = var.location
  resource_group_name = module.resource_group.name

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# Storage Account  (AVM)
# ---------------------------------------------------------------------------
module "storage" {
  source  = "Azure/avm-res-storage-storageaccount/azurerm"
  version = "0.2.9"

  name                = "stmad${var.team_name}${var.environment}"
  resource_group_name = module.resource_group.name
  location            = var.location

  account_kind             = "StorageV2"
  account_tier             = "Standard"
  account_replication_type = var.storage_replication
  is_hns_enabled           = true  # ADLS Gen2

  blob_properties = {
    versioning_enabled = true
    delete_retention_policy = {
      days = 7
    }
  }

  role_assignments = {
    team_mi = {
      role_definition_id_or_name = "Storage Blob Data Contributor"
      principal_id               = azurerm_user_assigned_identity.team.principal_id
      principal_type             = "ServicePrincipal"
    }
  }

  tags = local.common_tags
}

# Storage container (data boundary)
resource "azurerm_storage_container" "team_data" {
  name                  = "${var.team_name}-data"
  storage_account_name  = module.storage.name
  container_access_type = "private"
}

# ---------------------------------------------------------------------------
# Databricks Workspace  (AVM)
# ---------------------------------------------------------------------------
module "databricks_workspace" {
  source  = "Azure/avm-res-databricks-workspace/azurerm"
  version = "0.1.0"

  name                = "dbw-mad-${var.team_name}-${var.environment}"
  resource_group_name = module.resource_group.name
  location            = var.location

  sku = var.databricks_sku

  tags = local.common_tags
}

# ---------------------------------------------------------------------------
# RBAC – team AAD group gets Contributor on their own RG only
# ---------------------------------------------------------------------------
resource "azurerm_role_assignment" "team_rg_contributor" {
  scope                = module.resource_group.resource_id
  role_definition_name = "Contributor"
  principal_id         = var.aad_group_id
}

# ---------------------------------------------------------------------------
# Locals
# ---------------------------------------------------------------------------
locals {
  common_tags = {
    team        = var.team_name
    environment = var.environment
    managed_by  = "terraform"
    project     = "mad-platform"
  }
}
