# Default deployment parameters for ${country.name} (${country.summit_edition}).
# Dot-source before running deploy scripts:
#   . ./countries/${country.iso2}/params/defaults.ps1

$Global:DefaultLocation              = "${country.azure.primary_region}"
$Global:DefaultPairedLocation        = "${country.azure.paired_region}"
$Global:DefaultArcRegion             = "${country.azure.arc_region}"
$Global:DefaultAzureLocalInstanceLoc = "${country.azure.azure_local_instance_location}"
$Global:DefaultKeyVaultSku           = "${country.azure.cmk_hsm_sku}"
$Global:CountryCode                  = "${country.iso2}"
$Global:CountryName                  = "${country.name}"
$Global:InCountryRegionAvailable     = $false   # Egypt has no in-country Azure region (mid-2026)

Write-Host "Loaded ${country.name} defaults (closest region: $Global:DefaultLocation)" -ForegroundColor Yellow
Write-Warning "Egypt has no in-country Azure region. PDPL-regulated workloads must run on Azure Local + Arc."
