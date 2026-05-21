# Challenge EG-02 — Hybrid CBE-compliant landing zone with Azure Local + Arc

> **Country:** Egypt
> **Edition:** Sovereignty Summit Egypt 2026
> **Closest Azure region:** `uaenorth` (UAE North (closest hyperscale region to Egypt))

## The situation

You are the chief architect for **An Egyptian tier-1 bank operating mobile wallets under CBE cloud rules**.
The bank wants public-cloud elasticity, but the regulatory boundary is clear:
**customer financial PII, core banking records, token vaults, and the
re-identification path must remain physically in Egypt**.

This challenge is therefore the **Azure Local path** for Egypt. It stays in the
edition on purpose: when a workload or field set must remain in-country,
sovereign public cloud controls alone are **not enough**.

Your target architecture is a two-tier hybrid landing zone:

- **Regulated in-country tier:** Azure Local clusters in Egypt, projected into
  Azure through **Azure Arc**, hosting the core banking systems, token vault,
  and any de-tokenisation or re-identification services.
- **Permitted external tier:** `uaenorth` for tokenised or
  derived analytics, resiliency services, and non-regulated telemetry under a
  PDPC-approved transfer model.

## Your mission

Build the **CBE-ready hybrid landing zone** that proves the bank can keep the
sensitive tier in Egypt while still consuming public-cloud services for the
allowed data classes.

## Learning objectives

By the end of this challenge you should be able to:

- Explain why **Azure Local** is the right answer for some Egyptian workloads
  even when `uaenorth` is available nearby.
- Onboard an Azure Local environment into Azure Arc and treat the in-country
  estate as part of one governance plane.
- Design a tokenisation pipeline where the **vault, detokenisation logic, and
  key custody remain in Egypt**.
- Split telemetry and control evidence between in-country systems and the public
  cloud without weakening the sovereignty story.

## Objectives

- Stand up a 2-node **Azure Local** cluster (lab / simulated) and register it
  with Azure Arc.
- Onboard at least one VM and one AKS-on-Azure-Local or containerised workload
  as Arc-enabled resources.
- Keep the **token vault and re-identification service in Egypt** on Azure Local;
  export only tokenised or derived data to `uaenorth`.
- Apply an initiative named **`CBE Hybrid Landing Zone`** that:
  - denies regulated data services in `uaenorth` unless the
    dataset is tagged as tokenised / derived;
  - denies storage without `encryption.keySource = Microsoft.Keyvault`;
  - audits Arc-enabled machines missing in-country location metadata;
  - enforces a clear `cbe-tier` split between `regulated`, `derived`, and
    `management` assets.
- Route regulated telemetry to an **in-country SIEM** and non-regulated
  telemetry to a workspace in `uaenorth`.

## Success criteria

- [ ] `az connectedmachine list -g rg-eg-arc` shows the in-country tier machines
      as `Connected`.
- [ ] A workload tagged `cbe-tier=regulated` is **denied** if someone tries to
      place it directly in `uaenorth`.
- [ ] The token vault / re-identification service remains reachable only from the
      in-country Azure Local tier.
- [ ] Data exported to `uaenorth` appears as tokens,
      masked values, or derived aggregates only.
- [ ] A DR restore drill in `uaecentral` proves the backup is
      operationally useful but cannot reveal original customer identity without
      the in-country token vault.
- [ ] Your evidence pack maps each control back to the CBE Cloud Computing
      Framework and PDPL obligations.

## Guiding questions

- What is the difference between **keeping the encryption key in Egypt** and
  **keeping the identifiable data in Egypt**? Which requirement is stricter?
- If a data scientist says they only need analytics in `uaenorth`,
  what technical proof will you require before letting any dataset leave Egypt?
- Is it enough to tokenise in transit, or must the token vault and re-ID path
  also remain in-country? Why?
- Which telemetry can safely go to `uaenorth`, and which
  telemetry itself becomes regulated because it carries identifiers or business
  secrets?

## Egypt-specific pitfalls

- **Do not let the token vault drift to cloud:** once detokenisation or the
  master mapping table leaves Egypt, the whole hybrid design collapses.
- **Arc is a control plane, not a residency bypass:** Arc visibility does not
  mean the workload has moved to Azure; your evidence should make that explicit.
- **Derived-data sprawl:** once teams see `uaenorth` as
  available, they may start copying semi-raw data there. Force tagging and deny
  controls before that happens.
- **Key-wrapping story:** if you use BYOK or HSM-backed wrapping, document which
  key material never leaves Egypt and who controls destruction / recovery.

## Data-placement baseline

| Data / service | Default location | Rationale |
|---|---|---|
| Core banking records, customer master, account identifiers | Azure Local in Egypt | High-regulation, must remain in-country. |
| Token vault, detokenisation service, HSM-backed master keys | Azure Local in Egypt | Re-identification boundary stays in-country. |
| Tokenised analytics events, derived fraud features, masked reporting extracts | `uaenorth` | Cross-border only after tokenisation / permit. |
| DR copies of tokenised backups | `uaecentral` | Operational resilience without exposing raw identity. |

## Regulatory anchors

- PDPL Law 151 of 2020
- Executive Regulations — Ministerial Decree 816 of 2025
- Central Bank of Egypt: <https://www.cbe.org.eg/>
- Personal Data Protection Centre (PDPC): <https://pdpc.gov.eg/>

## Stretch goals

- Add Azure Policy exemptions that require both `pdpc-permit-id` and
  `tokenisation-pattern=approved` before a derived dataset may land in
  `uaenorth`.
- Project the token vault health and Arc machine posture into one workbook for
  the bank CISO.
- Extend the design with an exit / repatriation runbook showing how derived data
  feeds are cut off if the PDPC permit or CBE approval is withdrawn.
