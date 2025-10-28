using 'modules/aoai-deployments.bicep'

@description('Name der AOAI-Ressource genau wie im Portal')
param accountName = 'OpenAI-KI-Tutor-1'

@description('Zu deployende Modelle (Deployment-Alias & Modellname)')
param deployments = [
  { name: 'gpt4o-prod', model: 'gpt-4o' }
]
