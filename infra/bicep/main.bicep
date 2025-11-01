// =====================
// PARAMETERS
// =====================
param acrName string
param workspaceName string
param storageAccountName string
param userIdentityName string
param azureOpenAIName string
param keyVaultName string
param envName string
param postgresServerName string

param postgresServerAdminLogin string
@secure()
param postgresServerAdminPassword string

param location string = resourceGroup().location
param adminObjectId string 

@secure()
param litellmMasterKey string

param createOpenAIModels bool = false
param createAzureOpenAI bool = false
param azureOpenAIApiVersion string

param openWebUIName string
param litellmName string
param openWebUIImage string
param litellmImage string

// Neue Parameter für VNet
param vnetName string = 'litellm-vnet'
param containerSubnetName string = 'containerapps-subnet'
param postgresSubnetName string = 'postgres-subnet'
param privateDnsZoneName string = 'privatelink.postgres.database.azure.com'

// =====================
// MODULES
// =====================

// ACR
module acrModule './modules/acr.bicep' = {
  name: 'deployAcr'
  params: {
    acrName: acrName
    location: location
  }
}

// Azure OpenAI
module azureOpenAIModule './modules/azureOpenAI.bicep' = if (createOpenAIModels) {
  name: 'deployAzureOpenAI'
  params: {
    openAIName: azureOpenAIName
    openAiApiVersion: azureOpenAIApiVersion
    createAzureOpenAI: createAzureOpenAI
    location: location
  }
}

// Log Analytics
module logsModule './modules/logAnalytics.bicep' = {
  name: 'deployLogAnalytics'
  params: {
    workspaceName: workspaceName
    location: location
  }
}

// Storage
module storageModule './modules/storage.bicep' = {
  name: 'deployStorage'
  params: {
    storageAccountName: storageAccountName
    location: location
  }
}

// =====================
// NETWORK SETUP (VNet + DNS)
// =====================

resource vnet 'Microsoft.Network/virtualNetworks@2023-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: ['10.10.0.0/16']
    }
    subnets: [
      {
        name: containerSubnetName
        properties: {
          addressPrefix: '10.10.0.0/23'
        }
      }
      {
        name: postgresSubnetName
        properties: {
          addressPrefix: '10.10.2.0/23'
          delegations: [
            {
              name: 'pgDelegation'
              properties: {
                serviceName: 'Microsoft.DBforPostgreSQL/flexibleServers'
              }
            }
          ]
        }
      }
    ]
  }
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneName
  location: 'global'
}

resource dnsLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: '${vnet.name}-link'
  properties: {
    virtualNetwork: {
      id: vnet.id
    }
    registrationEnabled: false
  }
}

// =====================
// POSTGRES (PRIVATE)
// =====================
module postgresModule './modules/postgres.bicep' = {
  name: 'deployPostgres'
  params: {
    serverName: postgresServerName
    administratorLogin: postgresServerAdminLogin
    administratorLoginPassword: postgresServerAdminPassword
    location: location
    vnetId: vnet.id
    subnetName: postgresSubnetName
    privateDnsZoneArmResourceId: privateDnsZone.id
  }
}

// =====================
// MANAGED IDENTITY
// =====================
resource userIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: userIdentityName
  location: location
}

// =====================
// KEY VAULT
// =====================
var azureOpenAIResourceId = resourceId('Microsoft.CognitiveServices/accounts', azureOpenAIName)
var azureOpenAIEndpointVal = !createAzureOpenAI 
  ? reference(azureOpenAIResourceId, azureOpenAIApiVersion, 'full').properties.endpoint 
  : azureOpenAIModule.outputs.azureOpenAIEndpoint
var azureOpenAIKeyVal = !createAzureOpenAI 
  ? listKeys(azureOpenAIResourceId, azureOpenAIApiVersion).key1 
  : azureOpenAIModule.outputs.azureOpenAIKey

module keyVaultModule './modules/keyVault.bicep' = {
  name: 'deployKeyVault'
  params: {
    keyVaultName: keyVaultName
    location: location
    openAIKeySecretValue: azureOpenAIKeyVal
    adminObjectId: adminObjectId
    managedIdentityObjectId: userIdentity.properties.principalId
    postgresPasswordSecretValue: postgresServerAdminPassword
    postgresUsernameSecretValue: postgresServerAdminLogin
    postgresURLSecretValue: 'postgresql://${postgresServerAdminLogin}:${postgresServerAdminPassword}@${postgresServerName}.postgres.database.azure.com:5432/${postgresServerName}?sslmode=require'
    litellmMasterKeySecretValue: litellmMasterKey
  }
}

// =====================
// CONTAINER ENVIRONMENT (VNet Integration)
// =====================
module containerEnvModule './modules/containerEnv.bicep' = {
  name: 'deployContainerEnv'
  params: {
    envName: envName
    location: location
    logsCustomerId: logsModule.outputs.workspaceId
    logsKey: logsModule.outputs.workspaceKey
    storageAccountName: storageModule.outputs.storageAccountName
    storageAccountKey: storageModule.outputs.storageAccountKey
    openWebUIShareName: storageModule.outputs.openWebUIShareName
    liteLLMShareName: storageModule.outputs.litellmConfigShareName
    vnetId: vnet.id
    subnetName: containerSubnetName
  }
}

// =====================
// CONTAINER APPS (LiteLLM + OpenWebUI)
// =====================
module containerAppsModule './modules/containerApps.bicep' = {
  name: 'deployContainerApps'
  params: {
    openWebUIName: openWebUIName
    liteLLMName: litellmName
    openWebUIImage: openWebUIImage
    liteLLMImage: litellmImage
    envId: containerEnvModule.outputs.environmentId
    userIdentityResourceId: userIdentity.id
    keyVaultName: keyVaultName
    azureOpenAIBaseUrl: azureOpenAIEndpointVal
    azureOpenAIApiVersion: azureOpenAIApiVersion
    location: location
  }
}
