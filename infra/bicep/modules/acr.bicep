param acrName string
param location string

resource acr 'Microsoft.ContainerRegistry/registries@2025-04-01' = {
  name: acrName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false  // Admin-Benutzer aus Sicherheitsgründen deaktiviert
    publicNetworkAccess: 'Enabled'
  }
}

output acrId string = acr.id
