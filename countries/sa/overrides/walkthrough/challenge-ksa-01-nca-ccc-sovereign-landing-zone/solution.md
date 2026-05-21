# Solution — Challenge KSA-01 (NCA CCC sovereign landing zone)

> Walkthrough for `${country.summit_edition}` / Challenge KSA-01.
> Primary region: `${country.azure.primary_region}`.

## 1. Create the management-group structure

```bash
az account management-group create --name mg-sovsummit-ksa --display-name "Sovereignty Summit KSA"
az account management-group create --name mg-sovsummit-ksa-platform --display-name "KSA Platform" --parent mg-sovsummit-ksa
az account management-group create --name mg-sovsummit-ksa-workloads --display-name "KSA Workloads" --parent mg-sovsummit-ksa
az account management-group create --name mg-sovsummit-ksa-dr --display-name "KSA DR Exception" --parent mg-sovsummit-ksa
```

Attach your subscriptions so only the `dr` scope can host approved recovery
artifacts outside the Kingdom.

## 2. Create in-country logging and key-custody services

```bash
az group create -n rg-ksa-platform -l ${country.azure.primary_region}

az monitor log-analytics workspace create   -g rg-ksa-platform   -n law-ksa-sovereign   -l ${country.azure.primary_region}

az keyvault create   --name kv-ksa-sovereign-$RANDOM   --resource-group rg-ksa-platform   --location ${country.azure.primary_region}   --sku ${country.azure.cmk_hsm_sku}   --enable-rbac-authorization true   --enable-purge-protection true   --retention-days 90
```

If your customer owns an on-prem HSM, import the wrapping key as BYOK; for the
lab, a Premium Key Vault-backed key is sufficient.

## 3. Build the NCA CCC initiative

Use the following policy bundle:

| Policy | Effect | Why |
|---|---|---|
| Allowed locations | Deny | Keep workloads in `${country.azure.primary_region}` by default. |
| Allowed locations for resource groups | Deny | Prevent RG-level drift. |
| Require tag `ksa-data-classification` | Deny | Supports NCA data classification. |
| Require tag `ksa-regulator` | Deny | Distinguishes NCA / SAMA regulated estates. |
| Require tag `ksa-dr-approved` on DR scope | Deny | Forces explicit approval for `${country.azure.paired_region}` use. |
| Storage accounts should use customer-managed key for encryption | DeployIfNotExists | Key custody in-country. |
| Key vaults should have purge protection enabled | Deny | Prevent destructive key loss. |
| Deploy diagnostic settings to Log Analytics | DeployIfNotExists | Keep audit telemetry in-country. |

```bash
az policy set-definition create   --name nca-ccc-sovereign-ksa   --display-name "NCA CCC Sovereign Landing Zone / KSA"   --management-group mg-sovsummit-ksa   --definitions @nca-ccc-sovereign-ksa.initiative.json   --params '{"allowedPrimary":{"value":["${country.azure.primary_region}"]},"allowedDr":{"value":["${country.azure.paired_region}"]}}'
```

## 4. Assign the initiative

```bash
az policy assignment create   --name nca-ccc-sovereign-ksa-assignment   --policy-set-definition nca-ccc-sovereign-ksa   --scope /providers/Microsoft.Management/managementGroups/mg-sovsummit-ksa   --mi-system-assigned   --location ${country.azure.primary_region}
```

Grant the assignment identity `Contributor`, `Key Vault Crypto Service
Encryption User`, and `Monitoring Contributor` on the platform resource group.

## 5. Prove CMK + in-country telemetry

```bash
ST_NAME=stksacmk$RANDOM

az storage account create   -n $ST_NAME   -g rg-ksa-platform   -l ${country.azure.primary_region}   --sku Standard_LRS   --tags ksa-data-classification=confidential ksa-regulator=NCA ksa-dr-approved=false

az storage account update   -n $ST_NAME   -g rg-ksa-platform   --encryption-key-source Microsoft.Keyvault
```

Use a diagnostic-setting policy remediation to point Activity Logs and resource
logs at `law-ksa-sovereign`.

## 6. Validate deny paths and evidence

```bash
az group create -n rg-deny-test -l westeurope    # expect RequestDisallowedByPolicy
az policy state list --management-group mg-sovsummit-ksa   --filter "ComplianceState eq 'NonCompliant'" -o table
```

Your evidence pack should map:

- Policy boundary + tags → NCA CCC governance / classification controls.
- CMK + purge protection → NCA CCC cryptography and resilience controls.
- In-country Log Analytics → NCA CCC monitoring + PDPL accountability.
- DR exception register → PDPL cross-border transfer governance + NCA third-party/cloud controls.
