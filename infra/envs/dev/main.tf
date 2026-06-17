# ---------------------------------------------------------------------------
# dev environment – instantiates one module call per team
# ---------------------------------------------------------------------------

terraform {
  required_version = ">= 1.5"

  # Uncomment and configure for real deployments:
  # backend "azurerm" {
  #   resource_group_name  = "rg-mad-tfstate"
  #   storage_account_name = "stmadtfstatedev"
  #   container_name       = "tfstate"
  #   key                  = "dev.terraform.tfstate"
  # }

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110"
    }
  }
}

provider "azurerm" {
  features {}
  # subscription_id is read from ARM_SUBSCRIPTION_ID env var
}

module "analytics" {
  source = "../../modules/team-workspace"

  team_name    = "analytics"
  environment  = "dev"
  location     = var.location
  aad_group_id = var.analytics_aad_group_id
}

module "ingest" {
  source = "../../modules/team-workspace"

  team_name    = "ingest"
  environment  = "dev"
  location     = var.location
  aad_group_id = var.ingest_aad_group_id
}
