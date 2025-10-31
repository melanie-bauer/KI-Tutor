@description('Name der Azure OpenAI Resource')
param openAIName string

@description('Name des Model Deployments in der OpenAI Resource')
param openAIDeploymentName string

// Azure OpenAI Service Ressource (Cognitive Services Account vom Typ OpenAI)
resource openAIAccount 'Microsoft.CognitiveServices/accounts@2023-05-01' existing = {
  name: openAIName
}

// Deployment des GPT-4o Modells innerhalb der OpenAI Resource
resource openAIModelDeployment 'Microsoft.CognitiveServices/accounts/deployments@2023-05-01' = {
  name: openAIDeploymentName
  parent: openAIAccount
  sku: {
    name: 'Standard'
    capacity: 1    // eine Instanz des Modells
  }
  properties: {
    model: {
      name: 'gpt-4o-mini'        // Modell-Name (GPT-4o Mini Variante)
      format: 'OpenAI'
      version: '2024-07-18'      // Modellversion (Datumsversion für GPT-4o)
    }
    raiPolicyName: 'Microsoft.Default'
    versionUpgradeOption: 'OnceCurrentVersionExpired'
  }
}


// Ausgabe der Endpunkt-URL und des API-Schlüssels für nachgelagerte Module
output azureOpenAIEndpoint string = openAIAccount.properties.endpoint
output azureOpenAIKey string = listKeys(openAIAccount.id, '2022-12-01').key1
