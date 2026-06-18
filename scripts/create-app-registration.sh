#!/bin/bash

export SUBSCRIPTION_ID=$(az account show --query id -o tsv)

az ad sp create-for-rbac \
  --name "gh-actions-sp" \
  --role Contributor \
  --scopes /subscriptions/$SUBSCRIPTION_ID

az ad sp list --display-name "gh-actions-sp" --query "[0].{appId:appId,id:id}" -o json
az account show --query "{subscriptionId:id,tenantId:tenantId}" -o json