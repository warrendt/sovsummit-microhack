# Challenge EG-03 — Sovereign public cloud in UAE North with in-country token vault

> **Country:** Egypt
> **Edition:** Sovereignty Summit Egypt 2026
> **Primary region for this path:** `uaenorth` (UAE North (closest hyperscale region to Egypt))
> **Paired region for resilience:** `uaecentral` (UAE Central)

## The situation

You are the platform architect for **Ministry of Communications and Information Technology (MCIT) citizen-services portal**.
The steering committee has rejected two simplistic answers:

- **"Egypt has no Azure region, so everything must stay on Azure Local."**
- **"uaenorth is close enough, so everything can just go there."**

The approved position is more precise:

1. **For data that PDPL does not require to stay in Egypt**, the team may use
   `uaenorth` as the nearest Azure hyperscale region.
2. **For data that PDPL, sector policy, or your own risk assessment says must
   remain in Egypt**, the authoritative copy, token vault, and re-identification
   path stay on **Azure Local + Arc** in Egypt.

Your task is to build the **sovereign public-cloud path** honestly: use
`uaenorth` and `uaecentral` with strong
platform controls, while keeping the in-country tokenisation boundary for the
restricted fields.

## Why `uaenorth`?

Use `uaenorth` for this pattern because it is:

- **the closest Azure hyperscale region to Egypt**, which reduces latency versus
  Europe-based alternatives;
- part of a **regional pair** with `uaecentral`, giving a clean
  approved-location story for resilience;
- a better **operational fit** for Arabic-language support, regional networking,
  and data-path proximity than a distant region;
- suitable only with an **adequacy / transfer assessment posture**, not an
  automatic adequacy assumption: the UAE has a mature privacy landscape, but you
  still need **PDPC permit approval, destination assessment, and documented
  safeguards** before relying on it for Egyptian personal data.

## Your mission

Build a **sovereign public-cloud landing zone** that proves `uaenorth`
can be used safely for the permitted data classes while the restricted identity
boundary remains in Egypt.

## Learning objectives

By the end of this challenge you should be able to:

- Defend when a workload belongs in `uaenorth` and when it
  belongs on Azure Local in Egypt.
- Pin resources to `uaenorth` / `uaecentral`
  with Azure Policy and deny everything else.
- Configure **Premium Key Vault** with **RSA-HSM CMK** and attach it to data
  services in the public-cloud tier.
- Build a **Private Link-first** architecture where public network access is off
  by default.
- Design a customer-controlled tokenisation pattern where restricted fields are
  substituted in Egypt before any dataset reaches `uaenorth`.

## Objectives

Build the landing zone with the following controls:

- Assign an initiative named **`Egypt Sovereign Public Cloud / UAE North`** that:
  - allows only `uaenorth` and `uaecentral`;
  - denies any storage, Key Vault, SQL or App Service resource with public network
    access enabled;
  - requires the tags `pdpc-permit-id`, `pdpl-data-category`,
    `must-stay-in-egypt`, and `tokenisation-pattern`.
- Provision a **Premium Key Vault** in `uaenorth` with purge
  protection, soft delete, RBAC permission model, and an **RSA-HSM** key for CMK.
- Provision a **Storage account** in `uaenorth` that uses the
  CMK, enforces **TLS 1.2**, and has **public network access disabled**.
- Use **Private Link / private endpoints** for Storage, Key Vault, SQL and any
  application tier that touches regulated data.
- Keep a **customer-controlled tokenisation layer in Egypt**:
  - token vault and mapping table on Azure Local in Egypt;
  - projected into Azure with **Azure Arc** for inventory and governance;
  - only tokenised values or derived attributes may cross into
    `uaenorth`.

## Explicit data-classification table

| Data class / field set | Default placement | Allowed in `uaenorth`? | Required safeguard |
|---|---|---|---|
| Public content, static web assets, non-personal operational metadata | `uaenorth` | Yes | Allowed-locations + Private Link where relevant |
| General personal data approved for transfer (for example support-case metadata, low-risk service telemetry without raw national ID) | `uaenorth` | Yes, with PDPC permit | CMK + Private Link + TIA + logging |
| Analytics datasets containing customer records after tokenisation / masking | `uaenorth` | Yes | Tokenise in Egypt first; no re-identification path in cloud |
| National ID numbers, passport numbers, full account numbers, raw customer master, health data, biometrics, token vault mapping tables | Azure Local in Egypt | No | Keep authoritative copy and re-ID path in-country |
| HSM-backed master keys, token vault secrets, re-identification services | Azure Local in Egypt | No | Customer-controlled custody in Egypt |

## Success criteria

- [ ] A deployment to `westeurope` is denied immediately by the allowed-locations
      initiative.
- [ ] `az keyvault show` confirms a **Premium** vault in `uaenorth`
      with purge protection and soft delete enabled.
- [ ] `az keyvault key show` confirms the CMK is `RSA-HSM`.
- [ ] `az storage account show` confirms:
      `encryption.keySource = Microsoft.Keyvault`,
      `minimumTlsVersion = TLS1_2`, and
      `publicNetworkAccess = Disabled`.
- [ ] Private endpoints exist for Storage and Key Vault, and the service DNS path
      resolves through private zones.
- [ ] A sample dataset sent to `uaenorth` contains tokenised
      values only for the PDPL-restricted fields.
- [ ] The evidence pack clearly shows which data classes remain on Azure Local in
      Egypt and which are allowed into `uaenorth`.

## Guiding questions

- If `uaenorth` is the nearest region, why is an
  **allowed-locations** policy still essential?
- Why is **Private Link everywhere** stronger evidence than simply enabling TLS on
  public endpoints?
- What breaks in your sovereignty story if the token vault mapping table or
  detokenisation API moves to the public cloud?
- How would you explain to a regulator that using `uaenorth`
  is compliant for one dataset but non-compliant for another in the same tenant?

## Egypt-specific pitfalls

- **Do not claim blanket UAE adequacy.** Treat the UAE as a destination that may
  pass PDPC assessment for some transfers, not as an automatically approved safe
  harbour.
- **Allowed locations without classification is weak.** Region pinning tells you
  where data can go; it does not tell you **which** data may go there.
- **Public endpoints undermine the message.** Even with CMK and TLS, leaving
  Storage or Key Vault publicly reachable weakens the sovereign-control story.
- **Tokenisation must be customer-controlled.** A cloud-hosted managed tokeniser is
  not the same thing as keeping the mapping table and re-ID boundary in Egypt.

## Regulatory anchors

- PDPL Law 151 of 2020
- Executive Regulations — Ministerial Decree 816 of 2025
- Personal Data Protection Centre (PDPC): <https://pdpc.gov.eg/>
- Central Bank of Egypt: <https://www.cbe.org.eg/>

## Stretch goals

- Add SQL Database and App Service to the same Private Link + CMK pattern.
- Publish the initiative as Bicep and fail CI if the allowed locations or public
  network deny effects are weakened.
- Add a workbook that shows, per data class, whether the authoritative copy sits
  in Egypt or in `uaenorth`.
