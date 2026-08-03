param principalId string
param description string

var dnsZoneContributorRole = roleDefinitions('DNS Zone Contributor')

resource pontifexDevDnsZone 'Microsoft.Network/dnsZones@2018-05-01' existing = {
  name: 'pontifex.dev'
}

resource principalDnsWrite 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, dnsZoneContributorRole.id, principalId)
  properties: {
    principalId: principalId
    roleDefinitionId: dnsZoneContributorRole.id
    principalType: 'ServicePrincipal'
    description: description
  }
  scope: pontifexDevDnsZone
}
