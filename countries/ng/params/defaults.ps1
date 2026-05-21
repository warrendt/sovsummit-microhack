# Default deployment parameters for ${country.name} (${country.summit_edition}).
# Dot-source this file before running deployment scripts in resources/ to get
# country-appropriate defaults:
#
#     . ./countries/${country.iso2}/params/defaults.ps1
#     ./common/resources/subscription-preparations/4-resource-groups.ps1
#
# Nigeria has no in-country Azure region, so these defaults point to the nearest
# practical public Azure region while regulated workloads remain on Azure Local
# + Arc inside Nigeria.

$Global:DefaultLocation              = "${country.azure.primary_region}"
$Global:DefaultPairedLocation        = "${country.azure.paired_region}"
$Global:DefaultArcRegion             = "${country.azure.arc_region}"
$Global:DefaultAzureLocalInstanceLoc = "${country.azure.azure_local_instance_location}"
$Global:DefaultKeyVaultSku           = "${country.azure.cmk_hsm_sku}"
$Global:CountryCode                  = "${country.iso2}"
$Global:CountryName                  = "${country.name}"
$Global:InCountryRegionAvailable     = $false

Write-Host "Loaded ${country.name} defaults (closest public region: $Global:DefaultLocation)" -ForegroundColor Yellow
Write-Warning "Nigeria has no in-country Azure region. Keep regulated PII on Azure Local + Arc in Nigeria; use $Global:DefaultLocation for derived/non-regulated workloads only."
