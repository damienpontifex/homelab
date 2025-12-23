param location string = resourceGroup().location
param tags object = resourceGroup().tags

var damienObjectId = '01c9f9ea-c5b3-4e43-a2f8-d60fa4ba6d8d'

resource kv 'Microsoft.KeyVault/vaults@2025-05-01' = {
  location: location
  name: 'pontifex-homelab'
  tags: tags
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: subscription().tenantId
    networkAcls: {
      bypass: 'None'
      defaultAction: 'Allow'
      ipRules: []
      virtualNetworkRules: []
    }
    accessPolicies: [
      { objectId: damienObjectId, tenantId: subscription().tenantId, permissions: { secrets: ['all'] } }
      {
        objectId: unpollerIdentity.properties.principalId
        tenantId: subscription().tenantId
        permissions: { secrets: ['get', 'list'] }
      }
    ]
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enableRbacAuthorization: false
  }
}

resource unpollerIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2025-01-31-preview' = {
  name: 'unpoller'
  location: location

  resource federation 'federatedIdentityCredentials' = {
    name: 'unpoller-federation'
    properties: {
      audiences: ['api://AzureADTokenExchange']
      issuer: 'https://homelab.pontifex.dev'
      subject: 'system:serviceaccount:unpoller:unpoller'
    }
  }
}
