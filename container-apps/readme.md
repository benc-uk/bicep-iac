# 📦🌐 Azure Container Apps

There are three templates in this directory

- simple.bicep
- wordpress-vnet.bicep
- keycloak-vnet.bicep - NOTE: WIP, lacking the first time database creation in MS-SQL

> NOTE: April 2022 - Currently Azure Container Apps are only available in a very small set of regions

## 📜 Wordpress VNet

Wordpress is old and crummy, but it provides a good example of application that requires a backend DB, needs to handle configuration that is passed from one resource to another (e.g. passwords and hostnames), and has a public front end. As such it presents a nice use case for Container Apps, and is indicative of the deployment of many other systems, e.g:

- Placing Container Apps into a VNet to access other resources privately
- Creating a VNET & subnets for use with Container Apps
- Combining with Container Instances, also deployed into the VNert
  
### Quick Deploy

To quickly deploy taking the defaults:
```bash
az deployment sub create --template-file ./wordpress-vnet.bicep --location westeurope 
```

### Limitations

Using Container Instances to run a database is a *spectacularly* bad idea with zero data persistence. Swapping this to Azure SQL with private link is an exercise left to the reader.

## 📜 Simple

This deploys a single container using the [Azure Container App service](https://docs.microsoft.com/en-gb/azure/container-apps/overview). You can use this as a template or starting point for deploying any container


### Parameters

| Name     | Description                                                           | Type   | Default                               |
| -------- | --------------------------------------------------------------------- | ------ | ------------------------------------- |
| name     | Name used for resource group, and base name for container & resources | string | _none_                                |
| location | Azure region for all resources                                        | string | _Same as deployment_                  |
| image    | Image to deploy                                                       | string | ghcr.io/benc-uk/nodejs-demoapp:latest |

### Quick Deploy

To quickly deploy taking the defaults:

```bash
az deployment sub create --template-file ./simple.bicep \
  --location westeurope \
  --parameters appName="my-demo-app"
```

