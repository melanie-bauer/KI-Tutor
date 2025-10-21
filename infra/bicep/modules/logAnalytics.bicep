param workspaceName string
param location string = resourceGroup().location
param retentionDays int = 30

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2022-10-01' = {
  name: workspaceName
  location: location
  properties: {
    sku: { name: 'PerGB2018' }
    retentionInDays: retentionDays
  }
}

output workspaceId string = logAnalytics.properties.customerId
output workspaceKey string = logAnalytics.listKeys().primarySharedKey
