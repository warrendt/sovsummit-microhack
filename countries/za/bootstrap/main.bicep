// Sovereignty Summit South Africa 2026 — foundation bootstrap
// Subscription-scope deployment that stands up everything an attendee needs
// to start Challenge 1 of the South Africa edition immediately.
//
// What this deploys:
//   - Resource group (workshop foundation) in southafricanorth
//   - Log Analytics workspace (so diagnostic data stays in-country)
//   - User-assigned managed identity (used by storage to reach Key Vault)
//   - Premium Key Vault (HSM-backed) with purge protection + soft delete + RBAC
//   - One HSM-protected RSA key with a rotation policy
//   - Storage account configured with CMK from the vault
//   - Policy initiative assignment: allowed locations restricted to
//     southafricanorth + southafricawest
//
// Scope: subscription. Run with:
//   az deployment sub create \
//     --location southafricanorth \
//     --template-file main.bicep \
//     --parameters main.bicepparam

targetScope = 'subscription'

@description('Primary Azure region for the workshop. Must be inside South Africa.')
param primaryLocation string = 'southafricanorth'

@description('Paired region for DR. Both regions must be inside South Africa for residency to hold.')
param pairedLocation string = 'southafricawest'

@description('Short prefix used in resource names. Lowercase, 2-6 chars.')
@minLength(2)
@maxLength(6)
param namePrefix string = 'sovza'

@description('Object ID of the human / group that should be Key Vault Administrator on day 1.')
param adminObjectId string

@description('Tag every resource with this attendee handle so cleanup is trivial.')
param attendeeTag string = 'sovsummit-za'

@description('Resource group resource IDs to exclude from residency policy (e.g. ArcBox/LocalBox in swedencentral).')
param residencyExcludedScopes array = [
  '${subscription().id}/resourceGroups/rg-arcbox'
  '${subscription().id}/resourceGroups/rg-localbox'
]

var rgName = 'rg-${namePrefix}-foundation'
var lawName = 'law-${namePrefix}-${uniqueString(subscription().id, namePrefix)}'
var kvName  = 'kv-${namePrefix}-${uniqueString(subscription().id, namePrefix)}'
var idName  = 'id-${namePrefix}-cmk'
var saName  = toLower('st${namePrefix}${uniqueString(subscription().id, namePrefix)}')
var keyName = '${namePrefix}-cmk-rsa'

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgName
  location: primaryLocation
  tags: {
    workshop: attendeeTag
    country: 'za'
    sovereignty: 'in-country-only'
  }
}

module foundation 'modules/foundation.bicep' = {
  scope: rg
  name: 'foundation'
  params: {
    location: primaryLocation
    lawName: lawName
    kvName: kvName
    idName: idName
    saName: saName
    keyName: keyName
    adminObjectId: adminObjectId
    tags: {
      workshop: attendeeTag
      country: 'za'
    }
  }
}

module residency 'modules/policy-residency.bicep' = {
  name: 'residency-policy'
  params: {
    namePrefix: namePrefix
    allowedLocations: [
      primaryLocation
      pairedLocation
    ]
    excludedScopes: residencyExcludedScopes
  }
}

output resourceGroup string = rg.name
output keyVault string = foundation.outputs.kvName
output logAnalyticsWorkspace string = foundation.outputs.lawName
output storageAccount string = foundation.outputs.saName
output managedIdentity string = foundation.outputs.idName
output residencyPolicyAssignment string = residency.outputs.assignmentId
