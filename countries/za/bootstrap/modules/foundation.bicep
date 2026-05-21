// Foundation resources for the South Africa edition: Log Analytics, Premium
// Key Vault (HSM-backed) with an HSM key + rotation policy, a user-assigned
// managed identity, and a storage account that uses the key as CMK.

@description('Region for all resources in this module.')
param location string

param lawName string
param kvName string
param idName string
param saName string
param keyName string
param adminObjectId string
param tags object = {}

resource law 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: lawName
  location: location
  tags: tags
  properties: {
    sku: { name: 'PerGB2018' }
    retentionInDays: 90
    features: { enableLogAccessUsingOnlyResourcePermissions: true }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource id 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-07-31-preview' = {
  name: idName
  location: location
  tags: tags
}

resource kv 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: kvName
  location: location
  tags: tags
  properties: {
    sku: {
      family: 'A'
      // CMK on Storage requires Premium for HSM-protected keys.
      name: 'Premium'
    }
    tenantId: subscription().tenantId
    enableRbacAuthorization: true
    enablePurgeProtection: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    publicNetworkAccess: 'Enabled' // tighten in Challenge 3 with private endpoints
  }
}

// Built-in roles
var kvAdminRoleId   = '00482a5a-887f-4fb3-b363-3b7fe8e74483' // Key Vault Administrator
var kvCryptoUserId  = '12338af0-0e69-4776-bea7-57ae8d297424' // Key Vault Crypto User

resource kvAdminAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: kv
  name: guid(kv.id, adminObjectId, kvAdminRoleId)
  properties: {
    principalId: adminObjectId
    principalType: 'User'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', kvAdminRoleId)
  }
}

resource kvCmkIdentityAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  scope: kv
  name: guid(kv.id, id.id, kvCryptoUserId)
  properties: {
    principalId: id.properties.principalId
    principalType: 'ServicePrincipal'
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', kvCryptoUserId)
  }
}

resource cmkKey 'Microsoft.KeyVault/vaults/keys@2023-07-01' = {
  parent: kv
  name: keyName
  dependsOn: [ kvAdminAssignment ]
  properties: {
    kty: 'RSA-HSM'
    keySize: 3072
    keyOps: [ 'wrapKey', 'unwrapKey' ]
    rotationPolicy: {
      lifetimeActions: [
        {
          action: { type: 'Rotate' }
          trigger: { timeAfterCreate: 'P180D' }
        }
        {
          action: { type: 'Notify' }
          trigger: { timeBeforeExpiry: 'P30D' }
        }
      ]
      attributes: { expiryTime: 'P2Y' }
    }
  }
}

resource sa 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: saName
  location: location
  tags: tags
  sku: { name: 'Standard_GRS' } // GRS pairs to southafricawest (in-country)
  kind: 'StorageV2'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: { '${id.id}': {} }
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
    allowBlobPublicAccess: false
    publicNetworkAccess: 'Enabled' // tighten in Challenge 3
    encryption: {
      keySource: 'Microsoft.Keyvault'
      identity: { userAssignedIdentity: id.id }
      keyvaultproperties: {
        keyvaulturi: kv.properties.vaultUri
        keyname: cmkKey.name
      }
      services: {
        blob: { enabled: true, keyType: 'Account' }
        file: { enabled: true, keyType: 'Account' }
      }
    }
  }
  dependsOn: [ kvCmkIdentityAssignment ]
}

output lawName string = law.name
output kvName  string = kv.name
output idName  string = id.name
output saName  string = sa.name
output keyId   string = cmkKey.id
