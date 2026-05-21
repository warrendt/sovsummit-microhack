// Subscription-scope assignment of the built-in 'Allowed locations' policy,
// pinned to ${country.name} regions so ${country.regulatory.primary_law} residency
// is enforced from minute one. Effect is Deny — non-compliant deployments are
// rejected at create time.

targetScope = 'subscription'

param namePrefix string
param allowedLocations array

// Resource group resource IDs to exclude from the residency policy. Used to
// host demo-only artefacts (ArcBox, LocalBox) that legitimately deploy to a
// region outside ${country.name} (e.g. swedencentral) because the upstream
// Jumpstart templates require it. Residency enforcement still applies to
// every other RG in the subscription.
param excludedScopes array = []

// 'Allowed locations' built-in policy definition ID
var allowedLocationsPolicyId = '/providers/Microsoft.Authorization/policyDefinitions/e56962a6-4747-49cd-b67b-bf8b01975c4c'
// 'Allowed locations for resource groups' built-in policy definition ID
var allowedRgLocationsPolicyId = '/providers/Microsoft.Authorization/policyDefinitions/e765b5de-1225-4ba3-bd56-1ac6695af988'

resource locationsAssignment 'Microsoft.Authorization/policyAssignments@2023-04-01' = {
  name: '${namePrefix}-allowed-locations'
  properties: {
    displayName: '[${country.iso2}] Allowed locations (resources)'
    description: 'Resources may only be deployed in ${country.name} regions to satisfy ${country.regulatory.primary_law} residency.'
    policyDefinitionId: allowedLocationsPolicyId
    enforcementMode: 'Default'
    notScopes: excludedScopes
    parameters: {
      listOfAllowedLocations: {
        value: allowedLocations
      }
    }
  }
}

resource rgLocationsAssignment 'Microsoft.Authorization/policyAssignments@2023-04-01' = {
  name: '${namePrefix}-allowed-rg-locations'
  properties: {
    displayName: '[${country.iso2}] Allowed locations (resource groups)'
    description: 'Resource groups may only be created in ${country.name} regions.'
    policyDefinitionId: allowedRgLocationsPolicyId
    enforcementMode: 'Default'
    notScopes: excludedScopes
    parameters: {
      listOfAllowedLocations: {
        value: allowedLocations
      }
    }
  }
}

output assignmentId string = locationsAssignment.id
