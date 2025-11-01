param openWebUIName string
param liteLLMName string
param openWebUIImage string
param liteLLMImage string
param envId string // Resource ID der Container Apps Environment
param userIdentityResourceId string // Resource ID der User-Assigned Managed Identity
param keyVaultName string
param azureOpenAIBaseUrl string
param azureOpenAIApiVersion string
param location string

// Open WebUI Container App (öffentlich erreichbar)
resource openWebUIApp 'Microsoft.App/containerApps@2025-07-01' = {
  name: openWebUIName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userIdentityResourceId}': {}
    }
  }
  properties: {
    managedEnvironmentId: envId
    configuration: {
      ingress: {
        external: true          // öffentlich zugänglich
        targetPort: 8080        // Open WebUI hört auf Port 8080
        transport: 'auto'
        allowInsecure: false    // HTTPS erzwingen
      }
      secrets: [
        {
          name: 'azure-openai-key'
          // Verweis auf Key Vault Secret (neueste Version)
          keyVaultUrl: 'https://${keyVaultName}.vault.azure.net/secrets/AzureOpenAIKey'
          identity: userIdentityResourceId
        }
      ]
    }
    template: {
      containers: [
        {
          name: 'openwebui'
          image: openWebUIImage
          resources: {
            cpu: 1
            memory: '2.0Gi'
          }
          env: [
            // Configure Open WebUI to use LiteLLM via the proxy URL and forward user info
            { name: 'OPENAI_API_BASE_URL', value: 'http://${liteLLMName}:4000' }
            { name: 'OPENAI_API_KEY', secretRef: 'azure-openai-key' }
            { name: 'OPENAI_API_VERSION', value: azureOpenAIApiVersion }
            { name: 'ENABLE_FORWARD_USER_INFO_HEADERS', value: 'True' }
          ]
          volumeMounts: [
            {
              volumeName: 'openwebui-files'
              mountPath: '/app/backend/data'
            }
          ]
        }
      ]
      volumes: [
        {
          name: 'openwebui-files'
          storageType: 'AzureFile'
          storageName: 'openwebui-files'  // entspricht dem envStorage-Namen in containerEnv.bicep
          mountOptions: 'nobrl'           // empfohlen für Azure Files bei SQLite
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
    }
  }
}

// LiteLLM Container App (internal, not exposed publicly)
resource liteLLMApp 'Microsoft.App/containerApps@2025-07-01' = {
  name: liteLLMName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userIdentityResourceId}': {}
    }
  }
  properties: {
    managedEnvironmentId: envId
    configuration: {
      ingress: {
        external: true // internal only, no public endpoint
        targetPort: 4000
        transport: 'auto'
      }
      secrets: [
        {
          name: 'azure-openai-key'
          keyVaultUrl: 'https://${keyVaultName}.vault.azure.net/secrets/AzureOpenAIKey'
          identity: userIdentityResourceId
        }
        {
          name: 'azure-postgres-url'
          keyVaultUrl: 'https://${keyVaultName}.vault.azure.net/secrets/PostgresConnectionString'
          identity: userIdentityResourceId
        }
        {
          name: 'litellm-master-key'
          keyVaultUrl: 'https://${keyVaultName}.vault.azure.net/secrets/LiteLLMMasterKey'
          identity: userIdentityResourceId
        }
      ]
      // (If LiteLLM image were in ACR, we could add registries: similar to above)
    }
    template: {
      containers: [
        {
          name: 'litellm-proxy'
          image: liteLLMImage
          resources: {
            cpu: 1
            memory: '2.0Gi'
          }
          env: [
            // LiteLLM proxy reads these to connect to Azure OpenAI
            { name: 'AZURE_API_BASE', value: azureOpenAIBaseUrl }
            { name: 'AZURE_API_VERSION', value: azureOpenAIApiVersion }
            { name: 'AZURE_API_KEY', secretRef: 'azure-openai-key' }
            { name: 'DATABASE_URL', secretRef: 'azure-postgres-url'}
            { name: 'LITELLM_MASTER_KEY', secretRef: 'litellm-master-key' }
          ]
          volumeMounts: [
            {
              volumeName: 'litellm-config'
              mountPath: '/app/config'
            }
          ]
        }
      ]
      volumes: [
        {
          name: 'litellm-config'
          storageType: 'AzureFile'
          storageName: 'litellm-config'
        }
      ]
      // no volume needed for LiteLLM in this prototype
      scale: {
        minReplicas: 1
        maxReplicas: 1
      }
    }
  }
}
