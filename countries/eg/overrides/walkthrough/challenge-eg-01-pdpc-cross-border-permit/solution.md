# Solution — Challenge EG-01 (PDPC cross-border permit)

> Walkthrough for `${country.summit_edition}` / Challenge EG-01.
> Closest Azure region: `${country.azure.primary_region}`.

## 1. Define transfer metadata up front

Use tags that let legal, security and platform teams answer the same question:
**what may leave Egypt, under which permit, and with which safeguards?**

| Tag | Example value | Why |
|---|---|---|
| `pdpc-permit-id` | `PDPC-XB-2026-014` | Links the workload to the approved transfer file. |
| `pdpl-data-category` | `general`, `sensitive`, `tokenised`, `anonymised` | Drives placement and safeguard decisions. |
| `eg-data-controller` | `MCIT Citizen Services` | Identifies the accountable controller. |
| `transfer-basis` | `permit+consent` | Records the legal basis actually used. |
| `tia-reference` | `TIA-EG-PORTAL-2026-03` | Links the deployment to the Transfer Impact Assessment. |
| `must-stay-in-egypt` | `true` / `false` | Forces the Azure Local vs public-cloud boundary. |

## 2. Build the initiative

Create a policy initiative such as **`PDPL Egypt Cross-Border Governance`**.
A practical bundle is:

| Policy | Effect | Notes |
|---|---|---|
| Allowed locations | Deny | Allow only `${country.azure.primary_region}`, `${country.azure.paired_region}`. |
| Allowed locations for resource groups | Deny | Closes the RG loophole. |
| Require a tag and its value on resources | Deny | Enforce the transfer metadata above. |
| Require a tag and its value on resource groups | Deny | Makes permit ownership visible at scope level. |
| Configure subscription to enable Microsoft Defender for Cloud (Standard) | DeployIfNotExists | Supports breach workflow. |
| Diagnostic settings to a Log Analytics workspace in `${country.azure.primary_region}` | DeployIfNotExists | Keeps audit evidence in the approved destination set. |

```bash
az policy set-definition create \
  --name pdpl-eg-crossborder \
  --display-name "PDPL Egypt Cross-Border Governance" \
  --management-group mg-sovsummit-eg \
  --definitions @pdpl-eg-crossborder.initiative.json \
  --params '{"allowedLocations":{"value":["${country.azure.primary_region}","${country.azure.paired_region}"]}}'
```

## 3. Wire the breach-notification path

In **Defender for Cloud → Workflow automation**, trigger a Logic App on a
high-severity alert. Pass the transfer metadata into the notification payload so
incident response does not need to reconstruct it manually.

```http
POST https://<pdpc-webhook>/breach
Content-Type: application/json

{
  "controller": "<eg-data-controller>",
  "permitId": "<pdpc-permit-id>",
  "category": "<pdpl-data-category>",
  "transferBasis": "<transfer-basis>",
  "tiaReference": "<tia-reference>",
  "detectedAt": "<utcNow()>",
  "summary": "<alert.description>"
}
```

Verify in Logic App run history that the workflow starts within
`${country.regulatory.breach_notification_hours}` hours of awareness.

## 4. Minimum TIA sections

Your Transfer Impact Assessment should cover at least:

1. Data subjects and data categories.
2. Why the workload is allowed in `${country.azure.primary_region}` instead of
   being retained on Azure Local in Egypt.
3. Destination country, recipients and onward-transfer chain.
4. Safeguards: CMK, TLS 1.2+, private connectivity, tokenisation, access control.
5. Retention and deletion.
6. Data-subject rights handling.
7. Regulator / legal contacts:
   - PDPC — <https://pdpc.gov.eg/>
   - CBE — <https://www.cbe.org.eg/>

## 5. Verify

```bash
az group create -n rg-deny-test -l westeurope
# expected: denied by region policy

az storage account create -n stuntagged -g rg-eg --location ${country.azure.primary_region} --sku Standard_LRS
# expected: denied by required-tag policy

az policy state list --management-group mg-sovsummit-eg \
  --filter "ComplianceState eq 'NonCompliant'" -o table
```

## 6. Evidence pack

Capture:

- the initiative definition and assignment;
- one denied deployment outside the approved region set;
- one denied untagged deployment;
- the Logic App run record for the breach workflow;
- the TIA reference tied to the workload tags.
