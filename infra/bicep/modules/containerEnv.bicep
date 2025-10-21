param envName string
param location string
param logsCustomerId string  // Log Analytics Workspace ID
param logsKey string         // Log Analytics shared key
param storageAccountName string
@secure()
param storageAccountKey string
param fileShareName string

// Managed Environment for Container Apps
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
    // (No virtual network integration in this prototype; environment will use default Azure network)
  }
}

// Attach Azure Files storage to the environment for persistent volumes
resource envStorage 'Microsoft.App/managedEnvironments/storages@2025-07-01' = {
  name: 'openwebui-files'   // identifier for the storage mount in this env
  parent: containerEnv
  properties: {
    azureFile: {
      accountName: storageAccountName
      shareName: fileShareName
      accountKey: storageAccountKey
      accessMode: 'ReadWrite'
    }
  }
}

output environmentId string = containerEnv.id
