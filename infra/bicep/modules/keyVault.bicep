param keyVaultName string
param location string
@secure()
param openAIKeySecretValue string // Azure OpenAI API-Schlüssel, der als Secret im Vault gespeichert wird
param adminObjectId string // AAD Objekt-ID eines Administrators (Benutzer oder Gruppe) für Vault-Zugriff
param managedIdentityObjectId string // Objekt-ID der User-Assigned Managed Identity (für Key Vault Leserechte)
@secure()
param postgresPasswordSecretValue string // Passwort für PostgreSQL-Datenbank, die als Secret im Vault gespeichert wird
@secure()
param postgresUsernameSecretValue string // Benutzername für PostgreSQL-Datenbank, die als Secret im Vault gespeichert wird
@secure()
param postgresURLSecretValue string // Verbindungs-URL für PostgreSQL-Datenbank, die als Secret im Vault gespeichert wird
@secure()
param litellmMasterKeySecretValue string


resource vault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    tenantId: subscription().tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
    // Access Policies: Admin (voller Zugriff auf Secrets) und Managed Identity (Leserechte)
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
    // ARM-Deployment darf auf den Vault zugreifen (für die Secret-Erstellung)
    enabledForTemplateDeployment: true
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

// Speichert den Azure OpenAI API Key als Secret im Key Vault
resource openAISecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: vault
  name: 'AzureOpenAIKey'
  properties: {
    value: openAIKeySecretValue
  }
}

// Speichert den LibreChat Encryption Key als Secret im Key Vault
resource litellmMasterKeySecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: vault
  name: 'LiteLLMMasterKey'
  properties: {
    value: litellmMasterKeySecretValue
  }
}

resource postgresUsernameSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: vault
  name: 'PostgresUsername'
  properties: {
    value: postgresUsernameSecretValue
  }
}

resource postgresPasswordSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: vault
  name: 'PostgresPassword'
  properties: {
    value: postgresPasswordSecretValue
  }
}

resource postgresURLSecret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: vault
  name: 'PostgresConnectionString'
  properties: {
    value: postgresURLSecretValue
  }
}

output vaultUri string = vault.properties.vaultUri
