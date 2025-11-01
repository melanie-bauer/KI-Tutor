param openAIName string
param location string
param createAzureOpenAI bool = false

param openAiApiVersion string

resource openAIService 'Microsoft.CognitiveServices/accounts@2025-09-01' existing = {
  name: openAIName
}

resource openAIServiceCreated 'Microsoft.CognitiveServices/accounts@2025-09-01' = if (createAzureOpenAI) {
  name: openAIName
  location: location
  sku: { name: 'S0' }
  kind: 'OpenAI'
  properties: {
    customSubDomainName: openAIName
    publicNetworkAccess: 'Enabled'
    networkAcls: {
      defaultAction: 'Allow'
      virtualNetworkRules: []
      ipRules: []
    }
  }
}

var models = loadJsonContent('../models.json').models

// Loop over each model in the loaded JSON and create a resource for it
@batchSize(1) // Ensure that the deployment is executed sequentially
resource openAiModels 'Microsoft.CognitiveServices/accounts/deployments@2023-10-01-preview' = [for (model, i) in models: {
  parent: openAIService
  name: model.deploymentName
  sku: {
    name: 'Standard' // Assuming the SKU is "Standard" for all models; adjust as needed
    capacity: model.capacity
  }
  properties: {
    model: {
      format: 'OpenAI'
      name: model.modelName
      version: model.version
    }
    versionUpgradeOption: 'OnceNewDefaultVersionAvailable'
    currentCapacity: model.capacity
    raiPolicyName: 'Microsoft.Default'
  }
}]


// Ausgabe der Endpunkt-URL und des API-Schlüssels für nachgelagerte Module
output azureOpenAIEndpoint string = reference(openAIService.id, openAiApiVersion, 'full').endpoint 
output azureOpenAIKey string = listKeys(openAIService.id, openAiApiVersion).key1

