using './main.bicep'

// Edit these before running. The build-za.sh helper auto-fills adminObjectId
// from the signed-in user if you leave it blank.

param primaryLocation = 'southafricanorth'
param pairedLocation  = 'southafricawest'
param namePrefix      = 'sovza'
param adminObjectId   = ''
param attendeeTag     = 'sovsummit-za'
