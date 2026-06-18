#!/bin/bash

APP_OBJECT_ID=$(az ad app list --display-name "gh-actions-sp" --query "[0].id" -o tsv)

cat > fic-branch-main.json <<'JSON'
{
  "name": "gh-main-branch",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:umutykaya/mad-platform-avm:ref:refs/heads/main",
  "description": "GitHub Actions access for main branch",
  "audiences": ["api://AzureADTokenExchange"]
}
JSON

az ad app federated-credential create \
  --id "$APP_OBJECT_ID" \
  --parameters fic-branch-main.json