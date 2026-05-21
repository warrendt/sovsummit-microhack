# Solution — Challenge QA-02 (QCB payments landing zone)

> Walkthrough for `${country.summit_edition}` / Challenge QA-02.
> Primary region: `${country.azure.primary_region}`.

## 1. Start with the regulatory shape, not the subnet map

QCB’s Cloud Computing Regulation gives you the headings for the whole landing zone:

- governance,
- register,
- due diligence,
- access / audit rights,
- business continuity,
- exit plan,
- key management,
- data protection.

The most important technical line for this lab is **QCB 21.4**: **PII and financial information must be processed within Qatar only**.
That means `${country.azure.paired_region}` can be used only for transformed or backup data.

## 2. Recommended subscription split

| Subscription | Purpose | Region rule |
|---|---|---|
| `sub-qa-payments-prod` | Live regulated payment processing | `${country.azure.primary_region}` only |
| `sub-qa-payments-shared` | Logging, Key Vault, policy, monitoring, DNS | `${country.azure.primary_region}` only |
| `sub-qa-payments-dr` | DR / analytics copies | `${country.azure.paired_region}` only for tokenised, masked or encrypted-backup data |

## 3. Control stack for Qatar Central

Because `${country.azure.primary_region}` does not currently offer Confidential Compute GA SKUs, use this equivalent-control stack:

| Risk | Control in this solution | Residual note |
|---|---|---|
| Cleartext exposure in storage | CMK-backed SQL / Storage / disks | Strong at-rest protection |
| Network exposure | Private endpoints, no public network access, segmented subnets | Strong in-transit / network control |
| Over-privileged operators | Separate RBAC for app, DB and key admins | Reduces insider blast radius |
| Sensitive columns in database | Always Encrypted, preferably with secure enclaves if supported by chosen SQL deployment | Column-level protection, but not full VM-memory confidentiality |
| DR data exposure | App-tier tokenisation or masking before replication | Raw identifiers never leave Qatar |
| Key misuse | HSM-backed Key Vault, purge protection, logging, least privilege | Keys remain in Qatar |

## 4. Policy initiative shape

Bundle these controls into **`QCB Payments Landing Zone`**:

| Policy | Effect | Scope |
|---|---|---|
| Allowed locations = `${country.azure.primary_region}` | Deny | prod + shared |
| Allowed locations = `${country.azure.paired_region}` | Deny | DR |
| Storage / SQL / disk encryption with CMK | Deny or DeployIfNotExists | all payment data stores |
| Public network access disabled | Deny | SQL / Storage / Key Vault |
| Required tags | Deny | all RGs and data resources |
| `QaDrOnlyTransformedData` | Deny | DR subscription |
| Diagnostics to Qatar Log Analytics | DeployIfNotExists | all |

Suggested required tags:

- `qcb-approval-id`
- `outsourcing-tier`
- `dr-transfer-approved`
- `nia-classification`
- `data-form`
- `exit-plan-id`

## 5. Example provisioning steps

```bash
az keyvault create \
  --name kv-qa-payments-$RANDOM \
  --resource-group rg-qa-payments-shared \
  --location ${country.azure.primary_region} \
  --sku ${country.azure.cmk_hsm_sku} \
  --enable-rbac-authorization true \
  --enable-purge-protection true

az storage account create \
  --name stqapayprod$RANDOM \
  --resource-group rg-qa-payments-prod \
  --location ${country.azure.primary_region} \
  --sku Standard_ZRS \
  --public-network-access Disabled
```

Then attach CMKs and private endpoints before any regulated data is loaded.

## 6. SQL protection decision

Use this branching logic:

- **If** your chosen Azure SQL deployment in `${country.azure.primary_region}` supports **Always Encrypted with secure enclaves**, use it for the most sensitive columns (payer identifiers, merchant settlement references, selected PAN-adjacent attributes).
- **If not**, protect those fields with deterministic encryption or app-tier tokenisation before they ever reach the DR path.

The key point is that `${country.azure.paired_region}` receives only transformed or backup data, never the detokenisation secret.

## 7. Negative tests

```bash
# Denied: raw production data store in DR
az sql server create -n sqlqadrraw -g rg-qa-payments-dr -l ${country.azure.paired_region} \
  --tags qcb-approval-id=QCB-2026-014 outsourcing-tier=critical \
         dr-transfer-approved=yes nia-classification=Restricted \
         data-form=raw-production exit-plan-id=EXIT-001

# Allowed path only for transformed data
az group create -n rg-qa-payments-dr-analytics -l ${country.azure.paired_region} \
  --tags qcb-approval-id=QCB-2026-014 outsourcing-tier=critical \
         dr-transfer-approved=yes nia-classification=Internal \
         data-form=tokenised exit-plan-id=EXIT-001
```

## 8. Residual-risk statement you should include

A good answer says this plainly:

> Qatar Central currently lacks GA Confidential Compute SKUs, so this design uses CMK, private connectivity, column-level protection and tokenisation as compensating controls. These materially reduce exposure, but they do not provide the same hardware-backed memory-confidentiality and attestation assurances that Azure Confidential VMs would provide.

## 9. QFC contrast

For `${country.scenarios.qfc_tenant}` you may allow a different analytics pattern under the separate QFC regime, but keep it in a **separate subscription / evidence pack**.
Do not let a QFC analytics exception weaken the QCB-regulated payment boundary.
