param openWebUIName string
param liteLLMName string
param openWebUIImage string
param liteLLMImage string
param envId string // Resource ID of the managed environment
param userIdentityResourceId string // Resource ID of the user-assigned identity
param keyVaultName string
param azureOpenAIBaseUrl string
param azureOpenAIApiVersion string

// Open WebUI Container App (exposed publicly)
resource openWebUIApp 'Microsoft.App/containerApps@2025-07-01' = {
  name: openWebUIName
  location: resourceGroup().location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      // Attach the same managed identity we created
      '${userIdentityResourceId}': {}
    }
  }
  properties: {
    managedEnvironmentId: envId
    configuration: {
      ingress: {
        external: true // publicly accessible
        targetPort: 8080 // Open WebUI listens on port 8080
        transport: 'auto'
        allowInsecure: false // enforce HTTPS (automatic redirect from HTTP)
      }
      secrets: [
        {
          name: 'azure-openai-key'
          // Reference to the Key Vault secret (latest version):contentReference[oaicite:26]{index=26}:contentReference[oaicite:27]{index=27}
          keyVaultUrl: 'https://${keyVaultName}.vault.azure.net/secrets/AzureOpenAIKey'
          identity: userIdentityResourceId // use the user-assigned identity to access Key Vault
        }
      ]
      registries: [
        // (Optional) If pulling a private image from ACR using managed identity, specify:
        // {
        //   server: '<your-acr-name>.azurecr.io',
        //   identity: userIdentityResourceId
        // }
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
            { name: 'OPENAI_API_BASE_URL', value: 'http://${liteLLMName}:4000/v1' }
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
          storageName: 'openwebui-files' // matches envStorage name in environment
          mountOptions: 'nobrl' // recommended for Azure Files when using SQLite
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
  location: resourceGroup().location
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
        external: false // internal only, no public endpoint
        targetPort: 4000
        transport: 'auto'
      }
      secrets: [
        {
          name: 'azure-openai-key'
          keyVaultUrl: 'https://${keyVaultName}.vault.azure.net/secrets/AzureOpenAIKey'
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

            {
              name: 'MODEL_LIST'
              value: '''[{"model_name":"gpt-4o","litellm_provider":"azure","azure_deployment":"gpt-4o-mini"}]'''
            }
          ]
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
