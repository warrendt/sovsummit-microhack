# Default deployment parameters for ${country.name} (${country.summit_edition}).
# Dot-source this file before running deployment scripts in resources/ to get
# country-appropriate defaults:
#
#     . ./countries/${country.iso2}/params/defaults.ps1

$Global:DefaultLocation              = "${country.azure.primary_region}"
$Global:DefaultPairedLocation        = "${country.azure.paired_region}"
$Global:DefaultArcRegion             = "${country.azure.arc_region}"
$Global:DefaultAzureLocalInstanceLoc = "${country.azure.azure_local_instance_location}"
$Global:DefaultKeyVaultSku           = "${country.azure.cmk_hsm_sku}"
$Global:CountryCode                  = "${country.iso2}"
$Global:CountryName                  = "${country.name}"
$Global:DefaultSovereignAligned      = $true

Write-Host "Loaded ${country.name} defaults (primary region: $Global:DefaultLocation, paired region: $Global:DefaultPairedLocation)" -ForegroundColor Green
