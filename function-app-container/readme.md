# ⚡📦 Containerized Azure Function App

This deploys an Azure Function App running a container image plus supporting resources

- App Service Plan
- Storage Account
- App Insights
- User Managed Identity

By default a simple demo container is deployed from `ghcr.io/benc-uk/func-demo:latest` which has two HTTP triggered functions. This uses the v4 Functions runtime and is written in Node.js. 
The [source is here](https://github.com/benc-uk/azure-samples/tree/master/func-mi-demo)

The two example functions are included in the **benc-uk/func-demo** image:

- `/api/helloWorld` - The default HTTP trigger created by `func new --template "HTTP trigger"`
- `/api/listResGroups` - Lists all the resource groups in the Azure subscription, an example of using managed identity

Rather than exposing hundreds of possible parameters, this is really designed as getting started template to be used as a basis for customizing and building your own template.

With some small modifications, system assigned managed identity can be used instead of user assigned (e.g. setting `systemAssignedIdentity: true` on the functionApp module)

> NOTE: If you see a "PrincipalNotFound" error when deploying it's because Azure AD is very slow, and generally pretty awful. Try running the deployment again
 
## Parameters

| Name     | Description                                                     | Type   | Default              |
| -------- | --------------------------------------------------------------- | ------ | -------------------- |
| appName  | Name used for resource group, and base name for other resources | string | func-demo            |
| location | Azure region for all resources                                  | string | _Same as deployment_ |
| registry | Registry where the container image is held                      | string | ghcr.io              |
| repo     | Image repo (name) to deploy and run                             | string | benc-uk/func-demo    |
| tag      | Image tag to deploy and run                                     | string | latest               |

## Quick Deploy

To quickly deploy taking the defaults, run the following:

```bash
az deployment sub create --template-file main.bicep \
  --location "uksouth"
```

To get the URLs to test the HTTP function, run the following

```bash
echo $(az deployment sub show --name main --query "properties.outputs.functionAppURL.value" -o tsv)/api/helloWorld\?name=Wendy
echo $(az deployment sub show --name main --query "properties.outputs.functionAppURL.value" -o tsv)/api/listResGroups
```
