param acrName string
param location string

resource acr 'Microsoft.ContainerRegistry/registries@2025-04-01' = {
  name: acrName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false  // disable admin user for security
    publicNetworkAccess: 'Enabled'
  }
}

output acrId string = acr.id
