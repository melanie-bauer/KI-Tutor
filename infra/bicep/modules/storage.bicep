param storageAccountName string
param location string = resourceGroup().location
param fileShareName string = 'openwebui-data'
param fileShareQuota int = 100  // 100 GB quota

resource storageAcct 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
  }
}

// Create a File Share in the storage account for Open WebUI data
resource fileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2022-09-01' = {
  name: '${storageAcct.name}/default/${fileShareName}'
  properties: {
    shareQuota: fileShareQuota
  }
}

output storageAccountName string = storageAcct.name
@secure()
output storageAccountKey string = storageAcct.listKeys().keys[0].value
output fileShareName string = fileShareName
