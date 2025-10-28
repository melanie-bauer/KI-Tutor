// infra/bicep/modules/aoai-deployments.bicep
@description('Name der bestehenden Azure OpenAI Ressource (Cognitive Services account)')
param accountName string

@description('Liste der zu erstellenden/zu aktualisierenden Deployments')
param deployments array = [ ]
  // Bsp: { name: 'gpt4o-prod', model: 'gpt-4o' }

@description('SKU-Name für Deployments (Standard bei Azure OpenAI)')
param skuName string = 'Standard'

@description('Kapazität/Instanzen für das Deployment')
param skuCapacity int = 1

// Bestehenden Account referenzieren – keine Neuanlage
resource account 'Microsoft.CognitiveServices/accounts@2025-07-01-preview' existing = {
  name: accountName
}

// Pro Eintrag wird ein Deployment erzeugt/aktualisiert
resource modelDeployments 'Microsoft.CognitiveServices/accounts/deployments@2025-07-01-preview' = [
  for d in deployments: {
    name: d.name
    parent: account
    sku: {
      name: skuName
      capacity: skuCapacity
    }
    properties: {
      model: {
        format: 'OpenAI'
        name: d.model
        // Optional: Version kann hier ergänzt werden
        // version: '2024-XX-YY'
      }
      // Optional: automatische Versionsupdates, falls gewünscht:
      // versionUpgradeOption: 'OnceNewDefaultVersionAvailable'
    }
  }
]

output createdDeploymentNames array = [for d in deployments: d.name]
