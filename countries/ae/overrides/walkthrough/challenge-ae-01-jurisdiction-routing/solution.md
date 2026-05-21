# Solution — Challenge AE-01 (UAE jurisdiction routing)

> Walkthrough for `${country.summit_edition}` / Challenge AE-01.
> Primary region: `${country.azure.primary_region}`.

## 1. Start with the decision tree, not the subnet

For each processing boundary, answer these questions in order:

1. Is this a **government authority / government-data** case?
   - If yes, route to `public-sector-exception` and capture the governing law or
     mandate outside the federal PDPL flow.
2. If not, is the controller / processor **established in DIFC**?
   - If yes, route to `difc`.
3. If not, is the controller / processor **established in ADGM**?
   - If yes, route to `adgm`.
4. If not, treat it as **onshore federal PDPL**.
5. Add the **sector overlay** (`cbuae-bank`, `dha-health`, `tdra-telecom`, or
   `none`).
6. Confirm data stays in `${country.azure.primary_region}` or
   `${country.azure.paired_region}`. If it crosses legal perimeters, open an
   inter-perimeter transfer review even if the Azure region does not change.

## 2. Create the landing-zone hierarchy

```bash
az account management-group create --name mg-sovsummit-ae --display-name "Sovereignty Summit UAE"
az account management-group create --name mg-ae-federal --display-name "UAE Federal PDPL" --parent mg-sovsummit-ae
az account management-group create --name mg-ae-difc --display-name "DIFC" --parent mg-sovsummit-ae
az account management-group create --name mg-ae-adgm --display-name "ADGM" --parent mg-sovsummit-ae
az account management-group create --name mg-ae-exceptions --display-name "UAE Exceptions / Government Data" --parent mg-sovsummit-ae
```

Attach subscriptions (or lab scopes) so each legal perimeter has a clean
administrative boundary.

## 3. Define the mandatory classification model

| Tag | Allowed values | Why |
|---|---|---|
| `uae-regulatory-regime` | `federal-pdpl`, `difc`, `adgm`, `public-sector-exception` | Primary perimeter |
| `sector-overlay` | `none`, `cbuae-bank`, `dha-health`, `tdra-telecom` | Overlay regulator |
| `data-controller` | legal entity / authority name | Controller visibility |
| `data-processing-establishment` | `onshore`, `difc`, `adgm`, `government` | Encodes the decision-tree result |
| `interperimeter-transfer` | `yes`, `no` | Flags perimeter crossing |
| `exception-ticket` | approved legal / change reference | Required for exceptions |

## 4. Build the `UAE Jurisdiction Routing` initiative

Recommended bundle:

| Policy | Effect | Why |
|---|---|---|
| Allowed locations | Deny | Keep workloads in `${country.azure.primary_region}` or `${country.azure.paired_region}` |
| Allowed locations for resource groups | Deny | Stop RG drift |
| Require mandatory tags | Deny | Force classification at create time |
| Custom policy: regime tag must match management-group scope | Deny | Prevent DIFC / ADGM / federal mix-ups |
| Custom policy: `public-sector-exception` requires `exception-ticket` | Deny | Forces legal sign-off |
| Custom policy: `interperimeter-transfer=yes` requires approved scope / tag | Audit or Deny | Makes perimeter crossing visible |
| Diagnostic settings to in-country Log Analytics | DeployIfNotExists | Keeps evidence in the UAE |

```bash
az policy set-definition create \
  --name uae-jurisdiction-routing \
  --display-name "UAE Jurisdiction Routing" \
  --management-group mg-sovsummit-ae \
  --definitions @uae-jurisdiction-routing.initiative.json
```

## 5. Assignment pattern

Pass the expected scope bindings as initiative parameters:

```json
{
  "federalMgmtGroup": {"value": "mg-ae-federal"},
  "difcMgmtGroup":    {"value": "mg-ae-difc"},
  "adgmMgmtGroup":    {"value": "mg-ae-adgm"},
  "exceptionMgmtGroup":{"value": "mg-ae-exceptions"}
}
```

This lets one custom policy evaluate **tag + scope + exception status**
together.

## 6. Verify the deny paths

```bash
# Wrong region: should fail
az group create -n rg-ae-wrong-region -l westeurope

# Wrong legal perimeter: should fail in the federal scope
az deployment sub create \
  --location ${country.azure.primary_region} \
  --template-file main.bicep \
  --parameters uaeRegulatoryRegime=difc dataProcessingEstablishment=difc

# Missing exception ticket: should fail
az deployment sub create \
  --location ${country.azure.primary_region} \
  --template-file main.bicep \
  --parameters uaeRegulatoryRegime=public-sector-exception dataProcessingEstablishment=government
```

Review policy state:

```bash
az policy state list --management-group mg-sovsummit-ae \
  --filter "ComplianceState eq 'NonCompliant'" -o table
```

## 7. Evidence matrix example

| Workload | Establishment | Perimeter | Overlay | Azure scope | Transfer review? |
|---|---|---|---|---|---|
| Citizen-services API | Onshore | Federal PDPL | None / TDRA | `mg-ae-federal` | No |
| Refunds / escrow service | DIFC | DIFC DP Law | `cbuae-bank` if applicable | `mg-ae-difc` | Yes |
| Fraud analytics workspace | ADGM | ADGM DPR 2021 | None | `mg-ae-adgm` | Yes |
| Government records archive | Government | Public-sector exception | None | `mg-ae-exceptions` | Legal review |

The crucial lesson: **Azure region choice controls residency; legal
establishment controls the governing law. You must prove both.**
