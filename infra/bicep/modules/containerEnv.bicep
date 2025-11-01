param envName string
param location string
param logsCustomerId string
param logsKey string
param storageAccountName string
@secure()
param storageAccountKey string
param openWebUIShareName string
param liteLLMShareName string

param vnetId string
param subnetName string

resource containerEnv 'Microsoft.App/managedEnvironments@2025-07-01' = {
  name: envName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logsCustomerId
        sharedKey: logsKey
      }
    }
    vnetConfiguration: {
      infrastructureSubnetId: '${vnetId}/subnets/${subnetName}'
    }
  }
}

resource envStorageOpenWebUI 'Microsoft.App/managedEnvironments/storages@2025-07-01' = {
  name: 'openwebui-files'
  parent: containerEnv
  properties: {
    azureFile: {
      accountName: storageAccountName
      shareName: openWebUIShareName
      accountKey: storageAccountKey
      accessMode: 'ReadWrite'
    }
  }
}

resource envStorageLiteLLM 'Microsoft.App/managedEnvironments/storages@2025-07-01' = {
  name: 'litellm-config'
  parent: containerEnv
  properties: {
    azureFile: {
      accountName: storageAccountName
      shareName: liteLLMShareName
      accountKey: storageAccountKey
      accessMode: 'ReadWrite'
    }
  }
}

output environmentId string = containerEnv.id
