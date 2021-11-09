# 📦🌐 Azure Container App

This deploys a container using the [Azure Container App service](https://docs.microsoft.com/en-gb/azure/container-apps/overview). You can use this as a template or starting point for deploying any container

> NOTE: Nov 2021 - Currently Azure Container Apps are only available in a very small set of regions

## Parameters

| Name     | Description                                                           | Type   | Default                               |
| -------- | --------------------------------------------------------------------- | ------ | ------------------------------------- |
| name     | Name used for resource group, and base name for container & resources | string | _none_                                |
| location | Azure region for all resources                                        | string | _Same as deployment_                  |
| image    | Image to deploy                                                       | string | ghcr.io/benc-uk/nodejs-demoapp:latest |

## Quick Deploy

To quickly deploy taking the defaults:

```bash
az deployment sub create --template-file ./main.bicep \
  --location northeurope \
  --parameters appName="my-demo-app"
```
