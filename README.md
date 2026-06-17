# MAD Platform – Medior DevOps Engineer Technical Assignment

> **AI assistance note:** Perplexity AI assisted in generating the Terraform skeleton, Python boilerplate, and README structure. All code was reviewed and understood before submission.

---

## Design & Assumptions

### Architecture Overview

```
Azure Subscription
├── Resource Group: rg-mad-shared (shared infra: networking, Key Vault)
├── Resource Group: rg-mad-analytics
│   ├── Databricks Workspace: dbw-mad-analytics-<env>
│   ├── Storage Account: stmadanalytics<env>
│   │   └── Container: analytics-data
│   └── Managed Identity: mi-mad-analytics
└── Resource Group: rg-mad-ingest
    ├── Databricks Workspace: dbw-mad-ingest-<env>
    ├── Storage Account: stmadingest<env>
    │   └── Container: ingest-data
    └── Managed Identity: mi-mad-ingest
```

### Access Separation Strategy

- **One Databricks workspace per team** – total isolation of notebooks, jobs, clusters, and secrets.
- **One Storage Account + Container per team** – each team's Managed Identity is assigned `Storage Blob Data Contributor` on its own container only.
- **Azure RBAC** controls who can operate the workspace (Contributor on the Resource Group, scoped per team AAD group).
- **Databricks Unity Catalog** (future) or workspace-level ACLs enforce row/table-level access inside Databricks.
- **Key Vault** in the shared RG stores secrets referenced by both workspaces via secret scopes – teams cannot cross-read each other's secrets.

### Configuration layout

```
infra/
  modules/team-workspace/   # reusable per-team module
  envs/
    dev/
      analytics.tfvars      # team=analytics, env=dev
      ingest.tfvars          # team=ingest,     env=dev
    prod/
      analytics.tfvars
      ingest.tfvars
```

### Key assumptions

1. AAD groups `grp-mad-analytics` and `grp-mad-ingest` already exist.
2. A single Azure subscription is used; Resource Groups give billing and RBAC boundaries.
3. `Standard_LRS` storage is sufficient for dev; prod would use `ZRS` or `GRS`.
4. No VNet injection is modelled here – a next step for production.
5. Terraform state is stored in a shared Azure Storage backend (not configured locally).

---

## Terraform – How to Run

### Prerequisites

```bash
brew install terraform   # or https://developer.hashicorp.com/terraform/install
azure-cli login          # az login
```

### Run plan for the analytics team (dev)

```bash
cd infra/envs/dev
terraform init
terraform plan -var-file=analytics.tfvars
```

### Add a third team

Create `infra/envs/dev/finance.tfvars`:

```hcl
team_name   = "finance"
environment = "dev"
location    = "westeurope"
aad_group_id = "<finance-aad-group-object-id>"
```

Then add a module call in `infra/envs/dev/main.tf`:

```hcl
module "finance" {
  source      = "../../modules/team-workspace"
  team_name   = var.team_name
  environment = var.environment
  location    = var.location
  aad_group_id = var.aad_group_id
}
```

No other changes needed.

---

## Python Job – How to Run

### Local (PySpark)

```bash
pip install pyspark pytest

# Run the job
cd jobs/ingest && python transform_sales.py \
  --input_path  ./sample_data/sales_raw \
  --output_path ./output/sales_clean \
  --env dev

# Run tests
pytest jobs/ingest/tests/
```

### On Databricks

1. Upload `jobs/ingest/transform_sales.py` as a Databricks notebook or attach as a library.
2. Set job parameters via Databricks Widgets or `spark.conf.set()`.
3. Configure the cluster to use the team Managed Identity for ADLS access.

---

## What I Would Do Next

1. **VNet injection** – private endpoints for Databricks and Storage to remove public internet exposure.
2. **Unity Catalog** – centralised data governance with fine-grained table/column permissions across workspaces.
3. **CI/CD pipeline** – GitHub Actions workflow: `terraform fmt` → `validate` → `plan` on PR, `apply` on merge to main.
4. **Secret rotation** – automate Key Vault secret rotation and link to Databricks secret scopes.
5. **Monitoring** – Azure Monitor + Databricks cluster metrics dashboards, alerting on job failures.
6. **Cost controls** – auto-termination policies on all clusters, budget alerts per Resource Group.
