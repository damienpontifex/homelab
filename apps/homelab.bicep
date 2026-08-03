param location string = resourceGroup().location
param tags object = resourceGroup().tags

var damienObjectId = '1c46e2c1-6792-4d52-b66f-76c0d078713d'

resource kv 'Microsoft.KeyVault/vaults@2026-02-01' = {
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
        objectId: externalSecretsIdentity.properties.principalId
        tenantId: subscription().tenantId
        permissions: { secrets: ['get'] }
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

resource certManagerIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = {
  name: 'cert-manager'
  location: location
  properties: {
    isolationScope: 'None'
  }

  resource federation 'federatedIdentityCredentials' = {
    name: 'cert-manager-federation'
    properties: {
      audiences: ['api://AzureADTokenExchange']
      issuer: '${oidcStorageAccount.properties.primaryEndpoints.blob}${oidcStorageAccount::blobServices::oidcContainer.name}'
      subject: 'system:serviceaccount:cert-manager:cert-manager'
    }
  }
}

module certManagerDnsWrite 'homelab-dns-contributor.bicep' = {
  name: '${deployment().name}-cert-manager-dns-contributor'
  scope: resourceGroup('pontifex.dev')
  params: {
    description: 'Homelab cert-manager DNS Zone Contributor'
    principalId: certManagerIdentity.properties.principalId
  }
}

resource externalDnsIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = {
  name: 'external-dns'
  location: location
  properties: {
    isolationScope: 'None'
  }

  resource federation 'federatedIdentityCredentials' = {
    name: 'external-dns-federation'
    properties: {
      audiences: ['api://AzureADTokenExchange']
      issuer: '${oidcStorageAccount.properties.primaryEndpoints.blob}${oidcStorageAccount::blobServices::oidcContainer.name}'
      subject: 'system:serviceaccount:external-dns:external-dns'
    }
  }
}

module externalDnsDnsWrite 'homelab-dns-contributor.bicep' = {
  name: '${deployment().name}-external-dns-dns-contributor'
  scope: resourceGroup('pontifex.dev')
  params: {
    description: 'Homelab external-dns DNS Zone Contributor'
    principalId: externalDnsIdentity.properties.principalId
  }
}

resource externalSecretsIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = {
  name: 'external-secrets'
  location: location
  properties: {
    isolationScope: 'None'
  }

  resource federation 'federatedIdentityCredentials' = {
    name: 'external-secrets-federation'
    properties: {
      audiences: ['api://AzureADTokenExchange']
      issuer: '${oidcStorageAccount.properties.primaryEndpoints.blob}${oidcStorageAccount::blobServices::oidcContainer.name}'
      subject: 'system:serviceaccount:external-secrets:external-secrets'
    }
  }
}

resource oidcStorageAccount 'Microsoft.Storage/storageAccounts@2026-04-01' = {
  name: 'pontifexhomelaboidc'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    publicNetworkAccess: 'Enabled'
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: true
    allowSharedKeyAccess: true
    networkAcls: {
      ipv6Rules: []
      bypass: 'AzureServices'
      virtualNetworkRules: []
      ipRules: []
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: true
    encryption: {
      requireInfrastructureEncryption: false
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
    accessTier: 'Hot'
  }

  resource blobServices 'blobServices' = {
    name: 'default'
    properties: {
      deleteRetentionPolicy: {
        allowPermanentDelete: false
        enabled: false
      }
      staticWebsite: { enabled: false }
    }

    resource oidcContainer 'containers' = {
      name: 'oidc'
      properties: {
        defaultEncryptionScope: '$account-encryption-key'
        denyEncryptionScopeOverride: false
        publicAccess: 'Blob'
      }
    }
  }
}

module entraApplications 'homelab-entra-apps.bicep' = {
  name: '${deployment().name}-entra-apps'
  params: {
    oidcIssuerUrl: '${oidcStorageAccount.properties.primaryEndpoints.blob}${oidcStorageAccount::blobServices::oidcContainer.name}'
  }
}

output externalDnsClientId string = externalDnsIdentity.properties.clientId
output certManagerClientId string = certManagerIdentity.properties.clientId
output tenantId string = tenant().tenantId
