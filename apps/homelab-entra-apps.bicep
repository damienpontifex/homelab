extension 'br:mcr.microsoft.com/bicep/extensions/microsoftgraph/v1.0:1.0.0'

param oidcIssuerUrl string

var ownerEmails = [
  'damien@pontifex.dev'
  'damien.pontifex_gmail.com#EXT#@pontifex.onmicrosoft.com'
]

resource owners 'Microsoft.Graph/users@v1.0' existing = [for email in ownerEmails: { userPrincipalName: email }]
resource msGraphSP 'Microsoft.Graph/servicePrincipals@v1.0' existing = { appId: '00000003-0000-0000-c000-000000000000' }

// ============ //
//   ArgoCD    //
// =========== //
resource argocdApp 'Microsoft.Graph/applications@v1.0' = {
  displayName: 'ArgoCD Homelab'
  uniqueName: '8a8bca40-1d25-4a08-9972-8fbb39614168'
  web: {
    homePageUrl: 'https://argocd.pontifex.dev'
    redirectUris: [
      'https://argocd.pontifex.dev/auth/callback'

    ]
    // implicitGrantSettings: {
    //   enableAccessTokenIssuance: false
    //   enableIdTokenIssuance: false
    // }
  }
  groupMembershipClaims: 'ApplicationGroup'
  signInAudience: 'AzureADMyOrg'

  // Give the appropriate MS Graph scopes required to manage other app registrations
  requiredResourceAccess: [
    {
      resourceAppId: msGraphSP.appId
      resourceAccess: [
        for name in [ 'email', 'openid', 'profile' ]: {
          id: filter(msGraphSP.oauth2PermissionScopes, s => s.value == name)[0].id
          type: 'Scope'
        }
      ]
    }
  ]

  owners: { relationships: [for i in range(0, length(ownerEmails)): owners[i].id] }

  resource federatedIdentityCredentials 'federatedIdentityCredentials@v1.0' = {
    name: '${argocdApp.uniqueName}/homelab'
    audiences: ['api://AzureADTokenExchange']
    issuer: oidcIssuerUrl
    subject: 'system:serviceaccount:argocd:argocd-server'
  }
}

@description('Service principal for the application registration within our tenant')
resource argocdServicePrincipal 'Microsoft.Graph/servicePrincipals@v1.0' = {
  appId: argocdApp.appId
  owners: { relationships: [for i in range(0, length(ownerEmails)): owners[i].id] }
}

// ============= //
//   Grafana    //
// ============ //
// https://grafana.com/docs/grafana/latest/setup-grafana/configure-security/configure-authentication/azuread/#configure-application-roles-for-grafana-in-the-azure-portal
var grafanaAppRoles = [
  {
    description: 'Grafana server admin Users'
    displayName: 'Grafana Server Admin'
    id: '0cfc49a2-8ef2-4cb6-886a-ef1c83f43e9e'
    value: 'GrafanaAdmin'
  }
  {
    description: 'Grafana org admin Users'
    displayName: 'Grafana Org Admin'
    id: 'c58949ce-5aae-4bed-ad75-1c465aad5411'
    value: 'Admin'
  }
  {
    description: 'Grafana read only Users'
    displayName: 'Grafana Viewer'
    id: '811f8575-4995-491f-85f7-7dd1c6bcb92b'
    value: 'Viewer'
  }
  {
    description: 'Grafana Editor Users'
    displayName: 'Grafana Editor'
    id: '319fd603-d583-4be7-8425-c4fdf5817eed'
    value: 'Editor'
  }
]
resource grafanaApp 'Microsoft.Graph/applications@v1.0' = {
  displayName: 'Grafana Homelab'
  uniqueName: '17b8dc73-da7f-43be-9f9e-6646e6b5635b'
  web: {
    homePageUrl: 'https://grafana.pontifex.dev'
    redirectUris: [
      'https://grafana.pontifex.dev/login/azuread'
      'https://grafana.pontifex.dev'
    ]
  }
  signInAudience: 'AzureADMyOrg'

  // Give the appropriate MS Graph scopes required to manage other app registrations
  requiredResourceAccess: [
    {
      resourceAppId: msGraphSP.appId
      resourceAccess: [
        for name in [ 'email', 'openid', 'profile' ]: {
          id: filter(msGraphSP.oauth2PermissionScopes, s => s.value == name)[0].id
          type: 'Scope'
        }
      ]
    }
  ]

  appRoles: [
    for role in grafanaAppRoles: {
      id: role.id
      displayName: role.displayName
      description: role.description
      value: role.value
      allowedMemberTypes: ['User']
      isEnabled: true
    }
  ]

  owners: { relationships: [for i in range(0, length(ownerEmails)): owners[i].id] }

  resource federatedIdentityCredentials 'federatedIdentityCredentials@v1.0' = {
    name: '${argocdApp.uniqueName}/homelab'
    audiences: ['api://AzureADTokenExchange']
    issuer: oidcIssuerUrl
    subject: 'system:serviceaccount:monitoring:grafana'
  }
}

@description('Service principal for the application registration within our tenant')
resource grafanaServicePrincipal 'Microsoft.Graph/servicePrincipals@v1.0' = {
  appId: grafanaApp.appId
  owners: { relationships: [for i in range(0, length(ownerEmails)): owners[i].id] }
}

// =================== //
//   K8s API Server    //
// ================== //
resource k8sApiServerApp 'Microsoft.Graph/applications@v1.0' = {
  displayName: 'Homelab k8s API server'
  uniqueName: 'da3e9b33-69a2-4cad-968d-babbfe71e9c1'
  web: {
    homePageUrl: 'https://k8s.pontifex.dev'
  }
  signInAudience: 'AzureADMyOrg'

  // Give the appropriate MS Graph scopes required to manage other app registrations
  requiredResourceAccess: [
    {
      resourceAppId: msGraphSP.appId
      resourceAccess: [
        for name in [ 'email', 'openid', 'profile' ]: {
          id: filter(msGraphSP.oauth2PermissionScopes, s => s.value == name)[0].id
          type: 'Scope'
        }
      ]
    }
  ]

  owners: { relationships: [for i in range(0, length(ownerEmails)): owners[i].id] }
}

@description('Service principal for the application registration within our tenant')
resource k8sApiServerServicePrincipal 'Microsoft.Graph/servicePrincipals@v1.0' = {
  appId: k8sApiServerApp.appId
  owners: { relationships: [for i in range(0, length(ownerEmails)): owners[i].id] }
}
