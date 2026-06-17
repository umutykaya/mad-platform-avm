# Architecture Diagram

## Platform Slice – Two Teams

```
┌─────────────────────────────────────────────────────────────────────┐
│  Azure Subscription                                                 │
│                                                                     │
│  ┌─────────────────────────┐   ┌─────────────────────────────────┐ │
│  │ rg-mad-analytics-dev    │   │ rg-mad-ingest-dev               │ │
│  │                         │   │                                 │ │
│  │  dbw-mad-analytics-dev  │   │  dbw-mad-ingest-dev             │ │
│  │  (Databricks Premium)   │   │  (Databricks Premium)           │ │
│  │                         │   │                                 │ │
│  │  stmadanalyticsdev      │   │  stmadingestdev                 │ │
│  │  └── analytics-data     │   │  └── ingest-data                │ │
│  │                         │   │                                 │ │
│  │  mi-mad-analytics       │   │  mi-mad-ingest                  │ │
│  │  (Blob Contributor      │   │  (Blob Contributor              │ │
│  │   own container only)   │   │   own container only)           │ │
│  └─────────────────────────┘   └─────────────────────────────────┘ │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │ rg-mad-shared                                               │   │
│  │  kv-mad-shared-dev  (Key Vault – team secrets scoped        │   │
│  │                       per secret via Access Policies/RBAC)  │   │
│  └─────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘

AAD Groups:
  grp-mad-analytics  ──► Contributor on rg-mad-analytics-dev
  grp-mad-ingest     ──► Contributor on rg-mad-ingest-dev

  Neither group has any role on the other team's RG.
```

## Extending to a 3rd Team

Add one module block in `infra/envs/dev/main.tf` + one `*.tfvars` file. Zero changes to the module itself.
