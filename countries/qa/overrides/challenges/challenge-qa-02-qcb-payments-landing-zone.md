# Challenge QA-02 — QCB payments landing zone in Qatar Central with CMK + controlled UAE DR

> **Country:** ${country.name}
> **Edition:** ${country.summit_edition}
> **Primary region:** `${country.azure.primary_region}` (${country.azure.primary_region_display})
> **Secondary region for this lab:** `${country.azure.paired_region}` (${country.azure.paired_region_display})

## Scenario

You are the lead architect for **${country.scenarios.financial_tenant}**.
The bank wants its production payments platform to run in **${country.azure.primary_region}**
under the **Qatar Central Bank Cloud Computing Regulation**, with a contrast case
for **${country.scenarios.qfc_tenant}** under the separate **QFC Data Protection Regulations 2021**.

Two facts shape the design:

1. `${country.azure.primary_region}` is the in-country production region.
2. ${country.azure.confidential_compute_note}

## Objectives

Design a **QCB-aligned landing zone** that keeps the primary payment system in
`${country.azure.primary_region}` and only allows tightly governed replication to
`${country.azure.paired_region}`:

- Deploy a hub-spoke landing zone for the payments workload in `${country.azure.primary_region}` with:
  - a **${country.azure.cmk_hsm_sku} Key Vault** for CMK,
  - private endpoints for Storage / SQL / Key Vault,
  - Defender for Cloud + Azure Monitor,
  - deny-by-default public network access on data services.
- Build a policy initiative named **`QCB Payments Landing Zone`** that:
  - Denies production data resources outside `${country.azure.primary_region}`.
  - Denies Storage, SQL and disks unless encryption uses CMK.
  - Requires tags `qcb-approval-id`, `outsourcing-tier`, `dr-transfer-approved`, and `nia-classification`.
  - Allows replication to `${country.azure.paired_region}` only for tokenised, masked or backup data with `dr-transfer-approved=yes`.
- Document the **QFC contrast**: a separate subscription for `${country.scenarios.qfc_tenant}` may use `${country.azure.paired_region}` for analytics under the QFC regime, but still needs transfer-risk documentation, processor terms and breach handling.
- Because confidential compute is not available in `${country.azure.primary_region}`, use **tokenisation / masking before transfer** and keep de-tokenisation keys in `${country.azure.primary_region}`.

## Success criteria

- [ ] A storage account created without CMK is denied.
- [ ] A production SQL or storage deployment in `${country.azure.paired_region}` is denied unless the workload is tagged as approved DR data.
- [ ] `az keyvault show` confirms `sku.name = ${country.azure.cmk_hsm_sku}` and the vault is in `${country.azure.primary_region}`.
- [ ] A smoke test proves that data replicated to `${country.azure.paired_region}` is tokenised or encrypted backup content only.
- [ ] Your evidence pack distinguishes state-wide PDPPL/QCB obligations from the QFC-specific transfer and processor obligations.

## Hints

- QCB cloud controls normally drive provider due diligence, approval, audit rights, subcontractor visibility, resiliency testing and an exit plan — reflect these in tags, policy descriptions and evidence artefacts.
- Use **Allowed locations**, **Storage accounts should use customer-managed key for encryption**, **Azure Key Vault should use RBAC permission model**, and public-network-access deny policies as the baseline initiative components.
- A practical lab pattern is `payments-prod` in `${country.azure.primary_region}` plus `payments-dr` in `${country.azure.paired_region}` fed only by a tokeniser job.
- QCB regulation reference: ${country.regulatory.qcb_regulation_url}
- QFC data-protection reference: ${country.regulatory.qfc_dpo_url}

## Estimated duration
90 minutes.
