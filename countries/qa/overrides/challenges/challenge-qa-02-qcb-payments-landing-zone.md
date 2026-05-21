# Challenge QA-02 — QCB payments landing zone in Qatar Central without Confidential Compute

[Previous Challenge](challenge-qa-01-pdppl-nia-classification.md) — **[Home](../Readme.md)**

> **Country:** ${country.name}
> **Edition:** ${country.summit_edition}
> **Primary region:** `${country.azure.primary_region}` (${country.azure.primary_region_display})
> **Controlled DR region for this lab:** `${country.azure.paired_region}` (${country.azure.paired_region_display})

## The situation

You are the lead platform architect for **${country.scenarios.financial_tenant}**.
The bank is launching a new real-time merchant-payments platform and wants a landing zone that a QCB reviewer would recognise as credible on day one.

The design constraints are non-negotiable:

1. **Primary regulated processing stays in `${country.azure.primary_region}`.**
2. **QCB Cloud Computing Regulation 21.4 requires PII and financial information to be processed within Qatar.**
3. **${country.azure.confidential_compute_note}**
4. The bank still needs a **controlled DR / analytics pattern** in `${country.azure.paired_region}`.

Your job is to build a landing-zone design that stays faithful to the regulation rather than pretending Qatar Central has controls it does not yet have.

## Target architecture

Design a hub-spoke landing zone with these logical zones:

- **`sub-qa-payments-prod`** — production card / payer / merchant processing in `${country.azure.primary_region}`.
- **`sub-qa-payments-shared`** — shared security services in `${country.azure.primary_region}` (Key Vault, logging, DNS, policy, monitoring).
- **`sub-qa-payments-dr`** — tightly limited DR / analytics subscription in `${country.azure.paired_region}` for tokenised, masked or encrypted-backup data only.

Within `${country.azure.primary_region}`, your design must include:

- segmented subnets for web, API, tokenisation, data and management,
- **${country.azure.cmk_hsm_sku} Key Vault** with HSM-backed keys and RBAC,
- private endpoints for Storage, SQL and Key Vault,
- Azure Monitor / Log Analytics / Defender for Cloud,
- deny-by-default public network access on data services,
- controlled admin path (Bastion / JIT / PAM-style RBAC),
- application-tier tokenisation so vault-held detokenisation secrets never leave Qatar.

## Your mission

Produce a **QCB-aligned landing zone** that does all of the following.

### 1) Enforce a production-region boundary

Create a policy initiative called **`QCB Payments Landing Zone`** that:

- denies SQL, Storage, Key Vault and managed disks outside `${country.azure.primary_region}` for production subscriptions,
- allows `${country.azure.paired_region}` only in the DR subscription and only for explicitly approved data classes,
- requires these tags: `qcb-approval-id`, `outsourcing-tier`, `dr-transfer-approved`, `nia-classification`, `data-form`, `exit-plan-id`.

Recommended `data-form` values:

- `raw-production`
- `tokenised`
- `masked`
- `encrypted-backup`

### 2) Enforce key-management and private connectivity

Policy must also:

- deny Storage / SQL / disks unless encryption uses CMK where supported,
- deny public network access on SQL / Storage / Key Vault,
- require private endpoints and private DNS integration,
- require diagnostics and activity logs to land in `${country.azure.primary_region}`.

### 3) Replace Confidential Compute with a defensible equivalent-control stack

Because Qatar Central currently lacks Confidential Compute GA SKUs, use this stack instead:

- **CMK** in HSM-backed Key Vault,
- **SQL Always Encrypted** for the highest-value columns, using **secure enclaves if available for the chosen Azure SQL deployment / SKU in `${country.azure.primary_region}`**,
- **tokenisation at the application tier** for PAN-like identifiers, payer identifiers or other fields that must never appear raw in DR,
- **Private Link + network segmentation** so sensitive traffic stays on private paths,
- **strict operator separation** between app admins, DB admins and key custodians.

Be explicit about the trade-off: this is a strong compensating-control design, but it is **not the same thing** as hardware-backed encryption-in-use for VM memory.

### 4) Define the DR pattern

Design a pipeline where only one of these may reach `${country.azure.paired_region}`:

- tokenised rows,
- masked analytics extracts,
- encrypted backups.

The following must **not** leave `${country.azure.primary_region}`:

- raw payment events,
- raw PII,
- raw financial ledgers,
- detokenisation secrets,
- HSM-admin roles.

### 5) Prepare the regulator-ready evidence pack

Your evidence pack must include:

- cloud governance policy reference,
- provider due-diligence summary,
- cloud register entry,
- access / audit rights statement,
- business continuity and exit-plan references,
- key-management ownership model,
- a one-page residual-risk statement covering the Confidential Compute gap.

## Success criteria

- [ ] A storage account or SQL deployment without CMK / approved encryption settings is denied.
- [ ] Public network access on SQL / Storage / Key Vault is denied.
- [ ] A production data store in `${country.azure.paired_region}` is denied.
- [ ] A DR resource in `${country.azure.paired_region}` is allowed only when `data-form` is `tokenised`, `masked` or `encrypted-backup` and `dr-transfer-approved=yes`.
- [ ] `az keyvault show` confirms `sku.name = ${country.azure.cmk_hsm_sku}` in `${country.azure.primary_region}`.
- [ ] Sensitive columns are protected with Always Encrypted where available; otherwise the walkthrough explains the alternate tokenisation pattern and residual risk.
- [ ] Your evidence pack explicitly cites QCB governance, due diligence, audit, business continuity, exit-plan, key-management and data-protection duties.

## Guiding questions

- Which workloads belong in `${country.azure.primary_region}` because of QCB 21.4 even if DR pressure is high?
- Which secrets must remain under a separate custodianship model from the app team?
- If secure enclaves are unavailable for the exact SQL shape you picked, what compensating control still prevents cleartext from reaching DR?
- How do you prove that `${country.azure.paired_region}` only receives transformed or backup data, not live regulated production data?

## Hints

- QCB’s regulation explicitly covers **governance**, **register**, **due diligence**, **sub-contractor due diligence**, **access / audit rights**, **business continuity**, **exit plan**, **key management governance** and **data protection** — mirror those headings in your evidence pack.
- For network design, a practical pattern is hub + `spoke-prod-app`, `spoke-prod-data`, `spoke-shared-security`, and a separate DR subscription with no route back to detokenisation secrets.
- A useful deny rule is: `if location = ${country.azure.paired_region} and data-form not in ['tokenised','masked','encrypted-backup'] then deny`.
- Keep tokenisation / detokenisation keys in `${country.azure.primary_region}` only.
- Official references: ${country.regulatory.qcb_regulation_url} and ${country.regulatory.qfc_dpo_url}

## Estimated duration

105 minutes.
