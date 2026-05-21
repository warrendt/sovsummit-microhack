# Solution — Challenge NG-01 (NDPA cross-border + SDCMI)

> Walkthrough for `${country.summit_edition}` / Challenge NG-01.
> Closest Azure region: `${country.azure.primary_region}`.

## 1. Required tags

Define a tag taxonomy and enforce it with Azure Policy:

| Tag | Allowed values | Why |
|---|---|---|
| `ndpc-registration-tier` | `MDP-UHL` \| `MDP-EHL` \| `MDP-OHL` | Mirrors the NDPC 14 Feb 2024 guidance tiers. |
| `ndpa-transfer-basis` | `adequacy` \| `consent` \| `contract` \| `public-interest` \| `vital-interest` \| `legal-claims` | Maps to NDPA ss.41-43. |
| `ndpa-transfer-country` | `southafricanorth` \| `southafricawest` | Records the approved destination. |
| `ng-data-classification` | `regulated-pii` \| `tokenised` \| `anonymised` | Drives downstream controls. |

## 2. Create the policy initiative

Bundle:

| Policy | Effect | Notes |
|---|---|---|
| Allowed locations | Deny | Allow only `${country.azure.primary_region}`, `${country.azure.paired_region}`. |
| Require a tag and its value on resources | Deny | Enforce the four tags above. |
| Audit resources missing a tag | Audit | Catches RG drift. |
| Diagnostic settings to a Log Analytics workspace in `${country.azure.primary_region}` | DeployIfNotExists | Evidence trail for the derived tier. |
| Storage accounts should use customer-managed key | DeployIfNotExists | Supports NDPA s.24 security/accountability. |

```bash
az policy set-definition create \
  --name ndpa-ng-crossborder-sdcmi \
  --display-name "NDPA Nigeria Cross-Border + SDCMI" \
  --management-group mg-sovsummit-ng \
  --definitions @ndpa-ng-crossborder-sdcmi.initiative.json \
  --params '{"allowedLocations":{"value":["${country.azure.primary_region}","${country.azure.paired_region}"]}}'
```

## 3. Assign it with a managed identity

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
logging and key-management resource groups.

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
- transfer basis = adequacy assessment + contractual clauses, or another s.43 basis
- safeguards = CMK, TLS, confidential compute, tokenisation, Arc separation

## 5. Breach-notification Logic App (≤ ${country.regulatory.breach_notification_hours} h)

Create a **Defender for Cloud → Workflow automation** rule for
`Alert severity = High` that targets a Logic App whose first action posts the
required breach context to the NDPC incident mailbox / case endpoint.

```http
POST https://<ndpc-endpoint>/incident
Content-Type: application/json

{
  "controller": "NIMC citizen-services workload",
  "registrationTier": "MDP-UHL",
  "transferBasis": "adequacy",
  "detectedAt": "<utcNow()>",
  "affectedRegion": "${country.azure.primary_region}",
  "summary": "<alert.description>"
}
```

Validate run-history timestamps so the evidence shows the workflow can be
executed within `${country.regulatory.breach_notification_hours}` hours of
awareness under **NDPA s.40(2)**.

## 6. Verify

```bash
az group create -n rg-deny-test -l westeurope   # denied
az storage account create -n stuntaggedng -g rg-ng-derived \
  --location ${country.azure.primary_region} --sku Standard_LRS   # denied: missing tags
az policy state list --management-group mg-sovsummit-ng \
  --filter "ComplianceState eq 'NonCompliant'" -o table
```

## 7. Evidence mapping

Map the controls like this:

- tags + workbook → **NDPA ss.41-44**
- DPO details → **s.32**
- breach workflow → **s.40**
- transfer decision + adequacy notes → **ss.41-43**
- major-controller classification memo → **s.65** + **NDPC Guidance Notice (14 Feb 2024)**
