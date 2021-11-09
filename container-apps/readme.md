# 📦🌐 Container App

This deploys a demo container using Azure Container Apps service

## Parameters

| Name                  | Description                                                       | Type   | Default              |
| --------------------- | ----------------------------------------------------------------- | ------ | -------------------- |
| name                  | Name used for resource group, and base name for container & resources    | string | _none_               |
| location              | Azure region for all resources                                    | string | _Same as deployment_ |

## Quick Deploy

To quickly deploy taking the defaults:

```bash
az deployment sub create --template-file ./demoapp.bicep \
  --location northeurope
  --parameters appName="my-demo-app"
```
