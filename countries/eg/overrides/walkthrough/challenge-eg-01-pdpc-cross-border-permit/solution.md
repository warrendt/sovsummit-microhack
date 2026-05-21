# Solution — Challenge EG-01 (PDPC cross-border permit)

> Walkthrough for `${country.summit_edition}` / Challenge EG-01.
> Closest Azure region: `${country.azure.primary_region}`.

## 1. Required tags

Define a tag taxonomy enforced via policy:

| Tag | Allowed values | Why |
|---|---|---|
| `pdpc-permit-id` | string (PDPC reference) | Maps each resource to a specific cross-border permit. |
| `pdpl-data-category` | `sensitive` \| `general` \| `anonymised` | Drives downstream controls. |
| `eg-data-controller` | string (legal entity) | PDPL requires the controller to be identifiable. |

## 2. PDPL Egypt Cross-Border initiative

Bundle:

| Policy | Effect | Notes |
|---|---|---|
| Allowed locations | Deny | Allow only `${country.azure.primary_region}`, `${country.azure.paired_region}`. |
| Require a tag and its value on resources | Deny | `pdpc-permit-id`, `pdpl-data-category`, `eg-data-controller`. |
| Audit resources missing a tag | Audit | Catches drift on RGs. |
| Configure subscription to enable Microsoft Defender for Cloud (Standard) | DeployIfNotExists | Required for the breach pipeline. |
| Diagnostic settings to a Log Analytics workspace in `${country.azure.primary_region}` | DeployIfNotExists | Keeps audit trail close. |

```bash
az policy set-definition create \
  --name pdpl-eg-crossborder \
  --display-name "PDPL Egypt Cross-Border" \
  --management-group mg-sovsummit-eg \
  --definitions @pdpl-eg-crossborder.initiative.json \
  --params '{"allowedLocations":{"value":["${country.azure.primary_region}","${country.azure.paired_region}"]}}'
```

## 3. Breach-notification Logic App (≤ ${country.regulatory.breach_notification_hours} h)

In **Defender for Cloud → Workflow automation**, create a rule on
`Alert severity = High` that targets a Logic App whose first action is:

```http
POST https://<pdpc-webhook>/breach
Content-Type: application/json

{
  "controller": "<eg-data-controller from tag>",
  "permitId": "<pdpc-permit-id>",
  "detectedAt": "<utcNow()>",
  "category": "<pdpl-data-category>",
  "summary": "<alert.description>"
}
```

Verify in the Logic App run history that posts arrive < 72 h after the alert.

## 4. Transfer Impact Assessment (TIA) template

A minimum TIA covers (PDPC Executive Regulations Art. 9 et seq.):

1. Categories of data subjects and personal data.
2. Recipients in the destination country and onward-transfer chain.
3. Technical safeguards (CMK, TLS, Confidential Compute, tokenisation).
4. Legal basis for transfer (permit + consent / contract / vital interest).
5. Retention period and deletion mechanism.
6. Data-subject rights enforcement path (access, rectification, erasure).
7. Regulator contact points: ${country.regulatory.regulator_links}.

## 5. Verify

```bash
az group create -n rg-deny-test -l westeurope    # denied: PdplRegionRestriction
az storage account create -n stuntagged -g rg-eg --location ${country.azure.primary_region} --sku Standard_LRS   # denied: PdplTagRequired
az policy state list --management-group mg-sovsummit-eg --filter "ComplianceState eq 'NonCompliant'" -o table
```
