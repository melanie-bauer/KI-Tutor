param keyVaultName string
param location string
@secure()
param openAIKeySecretValue string // Azure OpenAI API key to store as secret
param adminObjectId string // AAD Object ID of an admin user/group for vault access
param managedIdentityObjectId string // Object ID of the user-assigned managed identity

resource vault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    tenantId: subscription().tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
    // Access policy for an admin (to manually manage secrets if needed)
    accessPolicies: [
      {
        tenantId: subscription().tenantId
        objectId: adminObjectId
        permissions: {
          secrets: ['get', 'list', 'set', 'delete']
        }
      }
      {
        tenantId: subscription().tenantId
        objectId: managedIdentityObjectId
        permissions: {
          secrets: ['get', 'list']
        }
      }
    ]
    // Allow Azure Resource Manager to access vault for template deployments
    enabledForTemplateDeployment: true
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

// Store the Azure OpenAI API key as a secret in Key Vault
resource openAISecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: vault
  name: 'AzureOpenAIKey'
  properties: {
    value: openAIKeySecretValue
  }
}

output vaultUri string = vault.properties.vaultUri
