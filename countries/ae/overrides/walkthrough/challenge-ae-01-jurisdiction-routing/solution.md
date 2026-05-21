# Solution — Challenge AE-01 (UAE jurisdiction routing)

> Walkthrough for `${country.summit_edition}` / Challenge AE-01.
> Primary region: `${country.azure.primary_region}`.

## 1. Create the landing-zone hierarchy

```bash
az account management-group create --name mg-sovsummit-ae --display-name "Sovereignty Summit UAE"
az account management-group create --name mg-ae-onshore --display-name "UAE Onshore / Federal PDPL" --parent mg-sovsummit-ae
az account management-group create --name mg-ae-difc --display-name "DIFC" --parent mg-sovsummit-ae
az account management-group create --name mg-ae-adgm --display-name "ADGM" --parent mg-sovsummit-ae
```

Attach the three lab subscriptions (or RG-backed lab scopes) so each regulatory
regime has a dedicated boundary.

## 2. Define the classification taxonomy

Minimum tags:

| Tag | Allowed values | Why |
|---|---|---|
| `uae-regulatory-regime` | `federal-pdpl`, `difc`, `adgm` | Determines which law and regulator apply. |
| `data-classification` | `public`, `internal`, `confidential`, `restricted` | Drives control depth. |
| `data-controller` | legal entity name | Makes the responsible controller visible. |
| `exception-ticket` | change / legal approval ID | Required only for approved exceptions. |

## 3. Build the `UAE Jurisdiction Routing` initiative

Recommended bundle:

| Policy | Effect | Why |
|---|---|---|
| Allowed locations | Deny | Keep all workloads in `${country.azure.primary_region}` or `${country.azure.paired_region}`. |
| Allowed locations for resource groups | Deny | Prevent RG drift. |
| Require a tag on resources | Deny | Force `uae-regulatory-regime`, `data-classification`, `data-controller`. |
| Custom policy: regime tag must match landing-zone scope | Deny | Prevent DIFC / ADGM workloads from landing in the wrong legal perimeter. |
| Diagnostic settings to Log Analytics in `${country.azure.primary_region}` | DeployIfNotExists | Preserve auditable policy evidence in-country. |

```bash
az policy set-definition create
  --name uae-jurisdiction-routing
  --display-name "UAE Jurisdiction Routing"
  --management-group mg-sovsummit-ae
  --definitions @uae-jurisdiction-routing.initiative.json
  --params '{"allowedLocations":{"value":["${country.azure.primary_region}","${country.azure.paired_region}"]}}'
```

## 4. Assignment pattern

Assign the initiative at `mg-sovsummit-ae` and pass a parameter map that binds
regime values to the expected management-group IDs:

```json
{
  "federalMgmtGroup": {"value": "mg-ae-onshore"},
  "difcMgmtGroup":    {"value": "mg-ae-difc"},
  "adgmMgmtGroup":    {"value": "mg-ae-adgm"}
}
```

That lets one custom policy evaluate **tag + scope** together.

## 5. Verify the deny paths

```bash
# Wrong region: should fail
az group create -n rg-ae-wrong-region -l westeurope

# Wrong legal perimeter: should fail in the onshore scope
az deployment group create -g rg-onshore-app
  --template-file main.bicep
  --parameters uaeRegulatoryRegime=difc dataClassification=confidential

az policy state list --management-group mg-sovsummit-ae
  --filter "ComplianceState eq 'NonCompliant'" -o table
```

## 6. Regulator evidence matrix

For each app / dataset, capture:

1. **Controller / processor establishment** (onshore, DIFC, ADGM).
2. **Applicable law** (PDPL, DIFC DP Law, ADGM DPR).
3. **Sector overlay** (CBUAE, DHA, government security baseline).
4. **Approved region set** (`${country.azure.primary_region}`, `${country.azure.paired_region}`).
5. **Exception record** if data crosses a legal perimeter.

That matrix is what your legal team reviews before onboarding a workload.
