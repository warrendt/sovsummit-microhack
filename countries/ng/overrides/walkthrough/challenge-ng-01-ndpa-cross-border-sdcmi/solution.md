# Solution — Challenge NG-01 (NDPA cross-border + SDCMI)

> Walkthrough for `${country.summit_edition}` / Challenge NG-01.
> Closest Azure region: `${country.azure.primary_region}`.

## 1. Define the evidence taxonomy first

Create the tags before you create the policy set, otherwise you will end up
retro-fitting evidence after the fact.

| Tag | Allowed values | Why |
|---|---|---|
| `ndpc-registration-tier` | `MDP-UHL` \| `MDP-EHL` \| `MDP-OHL` | Mirrors the NDPC 14 Feb 2024 guidance tiers. |
| `ndpa-transfer-basis` | `adequacy` \| `consent` \| `contract` \| `public-interest` \| `vital-interest` \| `legal-claims` | Captures the legal basis under NDPA ss.41-43. |
| `ndpa-transfer-instrument` | `ndpc-adequacy` \| `scc-equivalent` \| `intra-group-rules` \| `none-s43-basis` | Separates the legal basis from the operational mechanism. |
| `ndpa-transfer-country` | `southafricanorth` \| `southafricawest` | Records the approved destination region. |
| `ng-data-classification` | `restricted-raw` \| `tokenised` \| `anonymised` | Drives policy and routing decisions. |

## 2. Build the policy initiative

Bundle these controls:

| Policy | Effect | Notes |
|---|---|---|
| Allowed locations | Deny | Allow only `${country.azure.primary_region}`, `${country.azure.paired_region}`. |
| Allowed locations for resource groups | Deny | Stops RG drift. |
| Require tag and value on resources | Deny | Enforce the five tags above. |
| Audit resources missing a tag | Audit | Catches inherited drift. |
| Audit public-cloud resources tagged `restricted-raw` | Audit / Deny | Forces Nigeria-only handling for raw sensitive data. |
| Diagnostic settings to a Log Analytics workspace in `${country.azure.primary_region}` | DeployIfNotExists | Evidence trail for approved public-cloud resources. |
| Storage accounts should use customer-managed key | DeployIfNotExists | Supports NDPA s.24 security/accountability. |

```bash
az policy set-definition create \
  --name ndpa-ng-crossborder-sdcmi \
  --display-name "NDPA Nigeria Cross-Border + SDCMI" \
  --management-group mg-sovsummit-ng \
  --definitions @ndpa-ng-crossborder-sdcmi.initiative.json \
  --params '{"allowedLocations":{"value":["${country.azure.primary_region}","${country.azure.paired_region}"]}}'
```

## 3. Assign with a managed identity and lock exemptions down

```bash
az policy assignment create \
  --name ndpa-ng-crossborder-sdcmi-assignment \
  --policy-set-definition ndpa-ng-crossborder-sdcmi \
  --scope /providers/Microsoft.Management/managementGroups/mg-sovsummit-ng \
  --mi-system-assigned \
  --location ${country.azure.primary_region} \
  --params '{"allowedLocations":{"value":["${country.azure.primary_region}","${country.azure.paired_region}"]}}'
```

Grant the assignment identity permissions to create remediation artefacts in the
logging and key-management resource groups, but keep **policy exemption** rights
with a small set of governance admins only.

## 4. Prepare the NDPC registration workbook

Your workbook should follow **NDPA s.44(2)** exactly:

1. Controller name and address.
2. DPO name and address.
3. Description of personal data, categories and number of data subjects.
4. Processing purposes.
5. Recipient categories.
6. Destination country / region for transfers.
7. General description of safeguards, security measures and mechanisms.

For this challenge, populate the workbook with:

- destination = `${country.azure.primary_region}` / `${country.azure.paired_region}`
- transfer basis = adequacy assessment, NDPC-recognised SCC-equivalent / CBDTI,
  or another **s.43** basis
- safeguards = CMK, TLS, confidential compute, Private Link, tokenisation,
  Arc separation, approval workflow

## 5. Keep a transfer decision register

Track each cross-border workload in a simple table or workbook:

| Workload | Classification | Destination | Basis | Instrument | Safeguards | Approval owner |
|---|---|---|---|---|---|---|
| Identity analytics | `tokenised` | `${country.azure.primary_region}` | `public-interest` | `scc-equivalent` | CMK, Private Link, tokenisation | DPO |
| Breach evidence store | `anonymised` | `${country.azure.paired_region}` | `legal-claims` | `none-s43-basis` | CMK, immutable storage | Legal |

This is the fastest way to prove that `${country.azure.primary_region}` is an
approved destination, not an uncontrolled default.

## 6. Breach-notification Logic App (≤ ${country.regulatory.breach_notification_hours} h)

Create a **Defender for Cloud → Workflow automation** rule for
`Alert severity = High` that targets a Logic App whose first action posts the
required breach context to the NDPC incident mailbox / case endpoint.

```http
POST https://<ndpc-endpoint>/incident
Content-Type: application/json

{
  "controller": "NIMC citizen-services workload",
  "registrationTier": "MDP-UHL",
  "transferBasis": "public-interest",
  "transferInstrument": "scc-equivalent",
  "detectedAt": "<utcNow()>",
  "affectedRegion": "${country.azure.primary_region}",
  "summary": "<alert.description>"
}
```

Validate run-history timestamps so the evidence shows the workflow can be
executed within `${country.regulatory.breach_notification_hours}` hours of
awareness under **NDPA s.40(2)**.

## 7. Verify

```bash
az group create -n rg-deny-test -l westeurope   # denied
az storage account create -n stuntaggedng -g rg-ng-derived \
  --location ${country.azure.primary_region} --sku Standard_LRS   # denied: missing tags
az policy state list --management-group mg-sovsummit-ng \
  --filter "ComplianceState eq 'NonCompliant'" -o table
```

Also force one test resource to `ng-data-classification=restricted-raw` in
`${country.azure.primary_region}` and confirm it is blocked or audited by the
initiative.

## 8. Evidence mapping

Map the controls like this:

- DPO details → **NDPA s.32**
- breach workflow → **NDPA s.40**
- transfer decision register → **NDPA ss.41-43**
- workbook + registration metadata → **NDPA s.44**
- major-controller classification memo → **NDPA s.65** + **NDPC Guidance Notice (14 Feb 2024)**
- transfer instruments, templates, annual return discipline → **GAID 2025**
