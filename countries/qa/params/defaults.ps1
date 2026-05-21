# Default deployment parameters for ${country.name} (${country.summit_edition}).
# Dot-source this file before running deployment scripts in resources/:
#
#     . ./countries/${country.iso2}/params/defaults.ps1

$Global:DefaultLocation              = "${country.azure.primary_region}"
$Global:DefaultPairedLocation        = "${country.azure.paired_region}"
$Global:DefaultArcRegion             = "${country.azure.arc_region}"
$Global:DefaultAzureLocalInstanceLoc = "${country.azure.azure_local_instance_location}"
$Global:DefaultKeyVaultSku           = "${country.azure.cmk_hsm_sku}"
$Global:CountryCode                  = "${country.iso2}"
$Global:CountryName                  = "${country.name}"
$Global:InCountryRegionAvailable     = $true

Write-Host "Loaded ${country.name} defaults (primary region: $Global:DefaultLocation)" -ForegroundColor Green
Write-Warning "Qatar Central is nonpaired; use $Global:DefaultPairedLocation only as the customer-selected DR region for approved transfers."
Write-Warning "${country.azure.confidential_compute_note}"
