# 📦🌐 Azure Container Apps

There are three templates in this directory

- simple.bicep
- wordpress-vnet.bicep
- keycloak-vnet.bicep - NOTE: Incomplete, lacking the database creation in MS-SQL

## Simple

This deploys a single container using the [Azure Container App service](https://docs.microsoft.com/en-gb/azure/container-apps/overview). You can use this as a template or starting point for deploying any container

> NOTE: Nov 2021 - Currently Azure Container Apps are only available in a very small set of regions

### Parameters

| Name     | Description                                                           | Type   | Default                               |
| -------- | --------------------------------------------------------------------- | ------ | ------------------------------------- |
| name     | Name used for resource group, and base name for container & resources | string | _none_                                |
| location | Azure region for all resources                                        | string | _Same as deployment_                  |
| image    | Image to deploy                                                       | string | ghcr.io/benc-uk/nodejs-demoapp:latest |

### Quick Deploy

To quickly deploy taking the defaults:

```bash
az deployment sub create --template-file ./main.bicep \
  --location northeurope \
  --parameters appName="my-demo-app"
```

## Wordpress VNET

This is an example of several things

- Placing Container Apps into a VNEt to access other resources privately
- Creating a VNET & subnets for use with Container Apps
- Combining with Container Instances