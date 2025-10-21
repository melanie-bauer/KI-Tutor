@description('Deployment location for all resources')
param location string = resourceGroup().location

@description('Name for the Azure Container Registry (must be globally unique)')
param acrName string

@description('Name for the Container Apps managed environment')
param envName string = 'schoolai-env'

@description('Name for the Open WebUI container app')
param openWebUIName string = 'openwebui-app'

@description('Name for the LiteLLM container app')
param liteLLMName string = 'litellm'

@description('Container image for Open WebUI')
param openWebUIImage string = 'ghcr.io/open-webui/open-webui:main'

@description('Container image for LiteLLM proxy')
param liteLLMImage string = 'ghcr.io/berriai/litellm:main-latest'

@description('Azure OpenAI endpoint base URL (e.g., "https://<resource>.openai.azure.com")')
param azureOpenAIBaseUrl string

@description('Azure OpenAI API version (e.g., "2023-05-15")')
param azureOpenAIApiVersion string = '2023-05-15'

@secure()
@description('API key for Azure OpenAI (stored in Key Vault)')
param azureOpenAIKey string

@description('Name of the Azure Storage account (for file share)')
param storageAccountName string

@description('Name of the file share for Open WebUI persistent storage')
param fileShareName string = 'openwebui-fileshare'

@description('Name of the Key Vault to create for secrets')
param keyVaultName string

@description('Object ID of an admin user or group for Key Vault access policies')
param adminObjectId string

// Deploy Azure Container Registry
module acrModule './modules/acr.bicep' = {
  name: 'deployACR'
  params: {
    acrName: acrName
    location: location
  }
}

// Deploy Log Analytics workspace
module logsModule './modules/logAnalytics.bicep' = {
  name: 'deployLogAnalytics'
  params: {
    workspaceName: '${envName}-logs'
    location: location
  }
}

// Deploy Storage account and file share
module storageModule './modules/storage.bicep' = {
  name: 'deployStorage'
  params: {
    storageAccountName: storageAccountName
    fileShareName: fileShareName
    location: location
  }
}

// Deploy User-Assigned Managed Identity (for Container Apps)
resource userIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = {
  name: '${envName}-identity'
  location: location
}

// Deploy Key Vault and store the Azure OpenAI API key
module kvModule './modules/keyvault.bicep' = {
  name: 'deployKeyVault'
  params: {
    keyVaultName: keyVaultName
    location: location
    adminObjectId: adminObjectId
    // Pass the Managed Identity principal for Key Vault access policy
    managedIdentityObjectId: userIdentity.properties.principalId
    // Secrets to initialize in Key Vault:
    openAIKeySecretValue: azureOpenAIKey
  }
}

// Deploy Container Apps Environment (with Azure Files volume mount)
module envModule './modules/containerEnv.bicep' = {
  name: 'deployContainerEnv'
  params: {
    envName: envName
    location: location
    logsCustomerId: logsModule.outputs.workspaceId
    logsKey: logsModule.outputs.workspaceKey
    storageAccountName: storageModule.outputs.storageAccountName
    storageAccountKey: storageModule.outputs.storageAccountKey
    fileShareName: storageModule.outputs.fileShareName
  }
}

// Deploy the Open WebUI and LiteLLM container apps
module appsModule './modules/containerApps.bicep' = {
  name: 'deployContainerApps'
  params: {
    openWebUIName: openWebUIName
    liteLLMName: liteLLMName
    openWebUIImage: openWebUIImage
    liteLLMImage: liteLLMImage
    envId: envModule.outputs.environmentId
    userIdentityResourceId: userIdentity.id
    keyVaultName: keyVaultName
    azureOpenAIBaseUrl: azureOpenAIBaseUrl
    azureOpenAIApiVersion: azureOpenAIApiVersion
  }
  dependsOn: [
    kvModule
  ]
}
