# Default deployment parameters for ${country.name} (${country.summit_edition}).
# Dot-source this file before running deployment scripts in resources/ to get
# country-appropriate defaults:
#
#     . ./countries/${country.iso2}/params/defaults.ps1
#     ./common/resources/subscription-preparations/4-resource-groups.ps1
#
# The PS1 scripts honour these environment variables / globals.

$Global:DefaultLocation              = "${country.azure.primary_region}"
$Global:DefaultPairedLocation        = "${country.azure.paired_region}"
$Global:DefaultArcRegion             = "${country.azure.arc_region}"
$Global:DefaultAzureLocalInstanceLoc = "${country.azure.azure_local_instance_location}"
$Global:DefaultKeyVaultSku           = "${country.azure.cmk_hsm_sku}"
$Global:CountryCode                  = "${country.iso2}"
$Global:CountryName                  = "${country.name}"

Write-Host "Loaded ${country.name} defaults (region: $Global:DefaultLocation)" -ForegroundColor Green
