# ☁️🌐 Azure App Service - Web App

Pretty standard deployment of Azure App Service + Web App

## Parameters

| Name              | Description                                                | Type   | Default                |
| ----------------- | ---------------------------------------------------------- | ------ | ---------------------- |
| appName           | Name used for resource group and webapp name               | string | _none_                 |
| location          | Azure region for all resources                             | string | _Same as deployment_   |
| existingSvcPlanId | Existing App Service Plan, leave blank to create a new one | bool   | _true_                 |
| registry          | Registry holding the image to deploy                       | string | ghcr.io                |
| imageRepo         | Name of the repo & image to be deployed                    | string | benc-uk/nodejs-demoapp |

## Quick Deploy

To quickly deploy taking the defaults:

```bash
az deployment sub create --template-file ./main.bicep \
  --location uksouth \
  --parameters appName="my-web-app"
```
