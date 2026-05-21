# Solution — Challenge QA-01 (PDPPL + NIA classification)

> Walkthrough for `${country.summit_edition}` / Challenge QA-01.
> Primary region: `${country.azure.primary_region}`.

## 1. Define the taxonomy

Use one mandatory tag set everywhere:

| Tag | Allowed values | Why |
|---|---|---|
| `nia-classification` | `${country.regulatory.classification_scheme}` | Maps every workload to the NIA Policy v2.0 sensitivity level. |
| `pdppl-data-type` | `non-personal`, `personal`, `special-nature`, `anonymised` | Distinguishes normal personal data from higher-risk PDPPL data. |
| `data-owner` | ministry / entity name | Supports controller accountability. |
| `processing-purpose` | approved service identifier | Ties processing to a documented purpose. |
| `cross-border-adr-id` | ADR / waiver reference | Required before lower-classification data can use `${country.azure.paired_region}`. |

## 2. Create the initiative

Bundle these policies into **`Qatar PDPPL + NIA Data Classification`**:

| Policy | Effect | Notes |
|---|---|---|
| Allowed locations | Deny | Base allow-list = `${country.azure.primary_region}`, `${country.azure.paired_region}`. |
| Require tags on resources / resource groups | Deny | Enforces the taxonomy above. |
| Custom `QaRestrictedInCountryOnly` | Deny | If `nia-classification` is `Limited Access` or `Restricted`, then `location` must be `${country.azure.primary_region}`. |
| Custom `QaCrossBorderAdrRequired` | Deny | If `location = ${country.azure.paired_region}`, require `cross-border-adr-id` and keep the classification at `Public` or `Internal`. |
| Storage accounts should use customer-managed key for encryption | DeployIfNotExists | Mandatory for `special-nature` data stores. |
| SQL should use customer-managed keys | Audit / Deny | Use where the service supports it. |
| Diagnostic settings to Log Analytics in `${country.azure.primary_region}` | DeployIfNotExists | Keeps audit evidence in-country. |

```bash
az policy set-definition create \
  --name qa-pdppl-nia \
  --display-name "Qatar PDPPL + NIA Data Classification" \
  --management-group mg-sovsummit-qa \
  --definitions @qa-pdppl-nia.initiative.json \
  --params '{"allowedLocations":{"value":["${country.azure.primary_region}","${country.azure.paired_region}"]}}'
```

## 3. Assign and scope the deny logic

```bash
az policy assignment create \
  --name qa-pdppl-nia-assignment \
  --policy-set-definition qa-pdppl-nia \
  --scope /providers/Microsoft.Management/managementGroups/mg-sovsummit-qa \
  --mi-system-assigned \
  --location ${country.azure.primary_region}
```

Grant the managed identity rights to remediate diagnostics and CMK baselines.

## 4. Provision the CMK vault

```bash
az keyvault create \
  --name kv-sovsummit-qa-$RANDOM \
  --resource-group rg-qa-platform \
  --location ${country.azure.primary_region} \
  --sku ${country.azure.cmk_hsm_sku} \
  --enable-purge-protection true \
  --enable-rbac-authorization true
```

Use this vault for any storage or SQL resource tagged `pdppl-data-type=special-nature`.

## 5. Verify the deny paths

```bash
# Should be denied: restricted data outside Qatar Central
az group create -n rg-qa-restricted-dr -l ${country.azure.paired_region} \
  --tags nia-classification=Restricted pdppl-data-type=personal data-owner=MCIT processing-purpose=citizen-portal cross-border-adr-id=NA

# Should be denied: missing required tags
az storage account create -n stqamissingtags -g rg-qa-platform -l ${country.azure.primary_region} --sku Standard_LRS

# Compliance view
az policy state list --management-group mg-sovsummit-qa \
  --filter "ComplianceState eq 'NonCompliant'" -o table
```

## 6. Evidence pack

Create a short matrix:

- `nia-classification` + location deny → NIA v2.0 classification handling.
- `pdppl-data-type` + CMK/private endpoint requirements → PDPPL security obligations.
- `processing-purpose` → purpose limitation and processing records.
- `cross-border-adr-id` → executive-regulation transfer governance.

Include the regulator portal in the evidence README: `${country.regulatory.primary_regulator_url}`.
