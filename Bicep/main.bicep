extension microsoftGraphV1

targetScope = 'tenant'

@description('Display name of the Entra ID app registration')
param displayName string = 'bicep-devops-app'

@description('Unique identifier for the app registration (used for idempotency)')
param uniqueName string = 'bicep-devops-app'    // ← add this

resource app 'Microsoft.Graph/applications@v1.0' = {
  displayName: displayName
  uniqueName: uniqueName
  signInAudience: 'AzureADMyOrg'
}
