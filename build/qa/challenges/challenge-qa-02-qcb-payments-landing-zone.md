# Challenge QA-02 — QCB payments landing zone in Qatar Central with CMK + controlled UAE DR

> **Country:** Qatar
> **Edition:** Sovereignty Summit Qatar 2026
> **Primary region:** `qatarcentral` (Qatar Central)
> **Secondary region for this lab:** `uaenorth` (UAE North)

## Scenario

You are the lead architect for **A QCB-regulated bank launching a real-time merchant-payments platform in Doha**.
The bank wants its production payments platform to run in **qatarcentral**
under the **Qatar Central Bank Cloud Computing Regulation**, with a contrast case
for **A QFC-licensed asset manager receiving investor-reporting and risk analytics extracts** under the separate **QFC Data Protection Regulations 2021**.

Two facts shape the design:

1. `qatarcentral` is the in-country production region.
2. Azure Products by Region does not list Confidential Compute / confidential VMs for Qatar Central; this edition uses CMK, tokenisation and documented cross-border controls instead.

## Objectives

Design a **QCB-aligned landing zone** that keeps the primary payment system in
`qatarcentral` and only allows tightly governed replication to
`uaenorth`:

- Deploy a hub-spoke landing zone for the payments workload in `qatarcentral` with:
  - a **Premium Key Vault** for CMK,
  - private endpoints for Storage / SQL / Key Vault,
  - Defender for Cloud + Azure Monitor,
  - deny-by-default public network access on data services.
- Build a policy initiative named **`QCB Payments Landing Zone`** that:
  - Denies production data resources outside `qatarcentral`.
  - Denies Storage, SQL and disks unless encryption uses CMK.
  - Requires tags `qcb-approval-id`, `outsourcing-tier`, `dr-transfer-approved`, and `nia-classification`.
  - Allows replication to `uaenorth` only for tokenised, masked or backup data with `dr-transfer-approved=yes`.
- Document the **QFC contrast**: a separate subscription for `A QFC-licensed asset manager receiving investor-reporting and risk analytics extracts` may use `uaenorth` for analytics under the QFC regime, but still needs transfer-risk documentation, processor terms and breach handling.
- Because confidential compute is not available in `qatarcentral`, use **tokenisation / masking before transfer** and keep de-tokenisation keys in `qatarcentral`.

## Success criteria

- [ ] A storage account created without CMK is denied.
- [ ] A production SQL or storage deployment in `uaenorth` is denied unless the workload is tagged as approved DR data.
- [ ] `az keyvault show` confirms `sku.name = Premium` and the vault is in `qatarcentral`.
- [ ] A smoke test proves that data replicated to `uaenorth` is tokenised or encrypted backup content only.
- [ ] Your evidence pack distinguishes state-wide PDPPL/QCB obligations from the QFC-specific transfer and processor obligations.

## Hints

- QCB cloud controls normally drive provider due diligence, approval, audit rights, subcontractor visibility, resiliency testing and an exit plan — reflect these in tags, policy descriptions and evidence artefacts.
- Use **Allowed locations**, **Storage accounts should use customer-managed key for encryption**, **Azure Key Vault should use RBAC permission model**, and public-network-access deny policies as the baseline initiative components.
- A practical lab pattern is `payments-prod` in `qatarcentral` plus `payments-dr` in `uaenorth` fed only by a tokeniser job.
- QCB regulation reference: https://www.qcb.gov.qa/Documents/InformationSecurity/Cloud%20Computing%20Regulation.pdf
- QFC data-protection reference: https://www.qfc.qa/en/operating-with-qfc/data-protection

## Estimated duration
90 minutes.
