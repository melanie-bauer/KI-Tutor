param storageAccountName string
param location string
param openWebUIShareName string = 'openwebui-fileshare'
param litellmShareName string = 'litellm-config'
param fileShareQuota int = 100  // 100 GB Quota

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    dnsEndpointType: 'Standard'
    defaultToOAuthAuthentication: false
    publicNetworkAccess: 'Enabled'
    allowCrossTenantReplication: false
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    largeFileSharesState: 'Enabled'
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      requireInfrastructureEncryption: false
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }
}

resource storageAccount_fileService 'Microsoft.Storage/storageAccounts/fileServices@2023-04-01' = {
  parent: storageAccount
  name: 'default'
  properties: {
    protocolSettings: {
      smb: {}
    }
    cors: {
      corsRules: []
    }
    shareDeleteRetentionPolicy: {
      enabled: true
      days: 7
    }
  }
}

// Erstellt ein File Share für Open WebUI Persistenzdaten
resource fileShareOpenWebUI 'Microsoft.Storage/storageAccounts/fileServices/shares@2022-09-01' = {
  parent: storageAccount_fileService
  name: openWebUIShareName
  properties: {
    shareQuota: fileShareQuota
  }
}

// Erstellt ein File Share für LibreChat Konfiguration
resource litellmConfig_fileShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2023-04-01' = {
  parent: storageAccount_fileService
  name: litellmShareName
  properties: {
    accessTier: 'Hot'
  }
}

var litellmConfig = loadTextContent('../litellm_config.yaml')

// Upload litellm_config.yaml to litellm-config file share
resource uploadLitellmConfig_deploymentScript 'Microsoft.Resources/deploymentScripts@2023-08-01' = {
  name: 'upload-litellm-config'
  location: location
  kind: 'AzureCLI'
  properties: {
    azCliVersion: '2.59.0'
    timeout: 'PT5M'
    retentionInterval: 'PT1H'
    environmentVariables: [
      {
        name: 'AZURE_STORAGE_ACCOUNT'
        value: storageAccount.name
      }
      {
        name: 'AZURE_STORAGE_KEY'
        secureValue: storageAccount.listKeys().keys[0].value
      }
      {
        name: 'CONTENT'
        value: litellmConfig
      }
    ]
    scriptContent: 'echo "$CONTENT" > litellm_config.yaml && az storage file upload --source litellm_config.yaml -s ${litellmConfig_fileShare.name}'
  }
}

output storageAccountName string = storageAccount.name
@secure()
output storageAccountKey string = storageAccount.listKeys().keys[0].value
output openWebUIShareName string = openWebUIShareName
output litellmConfigShareName string = litellmShareName
