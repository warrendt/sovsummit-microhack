using './main.bicep'

// Edit these before running. The build-za.sh helper auto-fills adminObjectId
// from the signed-in user if you leave it blank.

param primaryLocation = '${country.azure.primary_region}'
param pairedLocation  = '${country.azure.paired_region}'
param namePrefix      = 'sovza'
param adminObjectId   = ''
param attendeeTag     = 'sovsummit-${country.iso2}'
