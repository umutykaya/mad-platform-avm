# GitHub Action Pipeline Config (Azure Credentials + Secrets via gh CLI)

## Overview

This guide explains how to configure Azure credentials for GitHub Actions and how to manage GitHub Secrets using the GitHub CLI (`gh`).

It covers:

1. Creating Azure credentials (Service Principal)
2. Storing credentials as GitHub Secrets
3. Referencing secrets in GitHub Actions workflows
4. Recommended secure approach using OpenID Connect (OIDC)

---

## Prerequisites

- Azure CLI installed and authenticated:
  ```bash
  az login
  ```
- GitHub CLI installed and authenticated:
  ```bash
  gh auth login
  ```
- Access to:
  - Azure subscription
  - GitHub repository admin/settings permissions (for secrets)

---

## Option 1: Service Principal with Client Secret (Quick Setup)

> Use this for initial setup. For production, prefer OIDC (see Option 2).

### 1) Create Service Principal credentials

```bash
# Optional: set active subscription
az account set --subscription "<SUBSCRIPTION_NAME_OR_ID>"

# Create service principal with RBAC scope
az ad sp create-for-rbac \
  --name "gh-actions-sp" \
  --role Contributor \
  --scopes /subscriptions/<SUBSCRIPTION_ID> \
  --sdk-auth
```

This returns JSON with keys like:

- `clientId`
- `clientSecret`
- `subscriptionId`
- `tenantId`

Save this output to a file (example: `azure-sp.json`) if using single-secret mode.

---

### 2) Store credentials in GitHub Secrets with `gh` CLI

Replace `<owner>/<repo>` with your repository.

#### A. Store as one JSON secret (recommended for this mode)

```bash
gh secret set AZURE_CREDENTIALS --repo <owner>/<repo> < azure-sp.json
```

#### B. Store as separate secrets

```bash
gh secret set AZURE_CLIENT_ID       --repo <owner>/<repo> --body "<clientId>"
gh secret set AZURE_TENANT_ID       --repo <owner>/<repo> --body "<tenantId>"
gh secret set AZURE_SUBSCRIPTION_ID --repo <owner>/<repo> --body "<subscriptionId>"
gh secret set AZURE_CLIENT_SECRET   --repo <owner>/<repo> --body "<clientSecret>"
```

#### C. Environment-scoped secrets (optional)

```bash
gh secret set AZURE_CLIENT_ID --env prod --repo <owner>/<repo> --body "<clientId>"
```

#### D. Verify secret names

```bash
gh secret list --repo <owner>/<repo>
```

---

### 3) Use secrets in workflow

#### Using single JSON secret

```yaml
name: Deploy

on:
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Azure Login
        uses: azure/login@v2
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}

      - name: Verify subscription
        run: az account show
```

#### Using separate secrets

```yaml
name: Deploy

on:
  workflow_dispatch:

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Azure Login
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

---

## Option 2 (Recommended): OIDC / Federated Credentials (No Client Secret)

This approach avoids storing long-lived Azure client secrets in GitHub.

### 1) Create App Registration / Service Principal
Create (or reuse) an Entra ID app + service principal and grant RBAC at minimum required scope.

### 2) Configure Federated Credential
In Azure (Entra ID), add a Federated Credential for your GitHub repo/branch/environment.

Typical subject patterns include branch or environment filters.

### 3) Store only non-secret IDs in GitHub

```bash
gh secret set AZURE_CLIENT_ID       --repo <owner>/<repo> --body "<clientId>"
gh secret set AZURE_TENANT_ID       --repo <owner>/<repo> --body "<tenantId>"
gh secret set AZURE_SUBSCRIPTION_ID --repo <owner>/<repo> --body "<subscriptionId>"
```

```bash
gh secret set AZURE_CLIENT_ID       --repo umutykaya/mad-platform-avm --body "3f454ad0-edba-49a2-b8e3-e8d355939ffd"
gh secret set AZURE_TENANT_ID       --repo umutykaya/mad-platform-avm --body "7544478d-c556-46fc-bf16-e9fb13329d2a"
gh secret set AZURE_SUBSCRIPTION_ID --repo umutykaya/mad-platform-avm --body "98014c53-83b7-4bfb-a4a4-2e31b0f22465"
```

### 4) Workflow requirements for OIDC

```yaml
name: Deploy (OIDC)

on:
  workflow_dispatch:

permissions:
  id-token: write
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - name: Azure Login (OIDC)
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Verify subscription
        run: az account show
```

---

## Secret Management with `gh` CLI (Cheat Sheet)

### Repository secrets

```bash
gh secret set SECRET_NAME --repo <owner>/<repo> --body "value"
gh secret list --repo <owner>/<repo>
gh secret delete SECRET_NAME --repo <owner>/<repo>
```

### Environment secrets

```bash
gh secret set SECRET_NAME --env <environment> --repo <owner>/<repo> --body "value"
gh secret list --env <environment> --repo <owner>/<repo>
gh secret delete SECRET_NAME --env <environment> --repo <owner>/<repo>
```

### Organization secrets (if needed)

```bash
gh secret set SECRET_NAME --org <org> --body "value" --visibility private
gh secret list --org <org>
```

---

## Security Best Practices

- Prefer **OIDC** over client secrets.
- Grant least privilege RBAC (avoid broad `Contributor` if not needed).
- Use environment protection rules for production.
- Rotate credentials regularly if using client secrets.
- Never print secrets in logs.
- Keep workflow permissions minimal (`contents: read`, `id-token: write` only when needed).

---

## Troubleshooting

### `Error: Login failed with Error: not all values are present`
- Ensure required secrets exist and are correctly named.
- Confirm workflow uses correct secret keys.

### `AADSTS7000215: Invalid client secret`
- Client secret expired or incorrect.
- Regenerate secret and update GitHub secret value.

### OIDC token exchange fails
- Verify federated credential subject/audience matches workflow context.
- Ensure workflow has:
  ```yaml
  permissions:
    id-token: write
  ```

### `gh secret set` fails with permission errors
- Confirm `gh auth status`.
- Ensure your token/session has admin access to repo/environment/org secrets.

---

## Minimal Recommended Setup (Production)

1. Configure Azure federated credentials (OIDC)
2. Set:
   - `AZURE_CLIENT_ID`
   - `AZURE_TENANT_ID`
   - `AZURE_SUBSCRIPTION_ID`
3. Use `azure/login@v2` + `permissions.id-token: write`
4. Scope RBAC to the smallest required resource group/subscription scope