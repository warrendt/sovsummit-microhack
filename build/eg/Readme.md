# Sovereignty Summit Egypt 2026 — MicroHack

> Country edition of the **Sovereignty Summit MicroHack** for **Egypt**.
> Generated from `common/` + `countries/eg/overrides/` via
> `tools/render.py`.

## ⚠️ Egypt context — no in-country Azure region

Unlike most editions, **there is no Azure region inside Egypt yet**. The
closest hyperscale region is **UAE North (closest hyperscale region to Egypt)**
(`uaenorth`). The Egypt edition therefore teaches **two
honest patterns in parallel**:

1. **Sovereign public cloud in `uaenorth` / `uaecentral`** for data that PDPL does **not** require to stay in Egypt, using strict region pinning, CMK in Premium Key Vault, Private Link, and customer-controlled tokenisation.
2. **Azure Local + Azure Arc inside Egypt** for data that PDPL, CBE policy, or your own risk assessment says must remain physically in-country.

The core design rule is simple: **do not assume Azure Local is the only answer just because Egypt lacks a data centre; do not assume `uaenorth` is acceptable for all data just because it is the closest region.**

## Country context

| Item | Value |
|---|---|
| Country | Egypt |
| In-country Azure region | ❌ none (closest: `uaenorth`) |
| Paired region | `uaecentral` (UAE Central) |
| Primary data-protection law | Personal Data Protection Law (Law No. 151 of 2020) |
| PDPL full-enforcement date | 2026-10-31 |
| Breach notification window | 72 hours to the PDPC |
| Cross-border transfer | Requires PDPC permit + adequacy assessment + data-subject consent |
| Regulatory frameworks in scope | PDPL Law 151/2020 + Executive Regulations (Decree 816 of 2025), Central Bank of Egypt (CBE) Cloud Computing Framework, NTRA telecom data rules, Egypt National Cybersecurity Strategy (EG-CERT) |
| Confidential compute SKUs (UAE North) | Standard_DC2as_v5, Standard_DC4as_v5, Standard_EC2as_v5, Standard_EC4as_v5 |
| Key Vault SKU | Premium |
| Sponsor | Microsoft Egypt |

### Scenarios used throughout the challenges
- **Public sector:** Ministry of Communications and Information Technology (MCIT) citizen-services portal
- **Financial services:** An Egyptian tier-1 bank operating mobile wallets under CBE cloud rules

### Egypt-specific notes
- The **Executive Regulations** (Ministerial Decree 816 of 2025) took effect on
  **1 Nov 2025** and created a **one-year grace period**, so full enforcement is
  expected from **1 Nov 2026** (practically: the compliance countdown ends on
  **2026-10-31**).
- Cross-border transfers remain **permit-led**: a controller / processor must be
  licensed with the **PDPC**, and a transfer outside Egypt requires a **separate
  PDPC permit or approval**, with destination, purpose, data categories and
  safeguards documented.
- Breach handling is now explicit in the Regulations: notify the **PDPC within
  72 hours** of awareness, then notify affected individuals within **three working days** where required.
- The **Central Bank of Egypt** (CBE) Cloud Computing Framework adds
  bank-specific obligations on top of PDPL: prior CBE approval for
  outsourcing core banking workloads, mandatory in-country handling for the
  most sensitive customer financial data, and an exit / repatriation plan.
- Practical pattern: keep token vaults, re-identification services, and any
  data that your legal position says must remain in Egypt on **Azure Local**;
  place permitted or derived workloads in `uaenorth` with
  **allowed-locations**, **Premium Key Vault CMK**, **Private Link**, and
  **field-level tokenisation**.

## Challenges (Egypt edition order)

1. Azure native sovereign controls (Policy, RBAC) — [`challenges/challenge-01.md`](challenges/challenge-01.md)
2. Encryption at rest with CMK — [`challenges/challenge-02.md`](challenges/challenge-02.md)
3. Encryption in transit (TLS) — [`challenges/challenge-03.md`](challenges/challenge-03.md)
4. Confidential VMs — [`challenges/challenge-04.md`](challenges/challenge-04.md)
5. Confidential AKS — [`challenges/challenge-05.md`](challenges/challenge-05.md)
6. Azure Local + Arc — [`challenges/challenge-06.md`](challenges/challenge-06.md)
7. **🇪🇬 PDPC cross-border permit + adequacy guardrails** — [`challenges/challenge-eg-01-pdpc-cross-border-permit.md`](challenges/challenge-eg-01-pdpc-cross-border-permit.md)
8. **🇪🇬 Hybrid CBE-compliant landing zone with Azure Local + Arc** — [`challenges/challenge-eg-02-hybrid-cbe-azure-local.md`](challenges/challenge-eg-02-hybrid-cbe-azure-local.md)
9. **🇪🇬 Sovereign public cloud in UAE North with tokenisation + in-country vault** — [`challenges/challenge-eg-03-sovereign-public-cloud-uaenorth.md`](challenges/challenge-eg-03-sovereign-public-cloud-uaenorth.md)

## Attribution

Based on the [Microsoft Sovereign Cloud MicroHack](https://github.com/microsoft/MicroHack/tree/main/03-Azure/01-03-Infrastructure/01_Sovereign_Cloud)
(MIT-licensed) by Jan Egil Ring, Ye Zhang, Murali Rao Yelamanchili and other
Microsoft contributors. Egypt customizations © Sovereignty Summit EG Chapter.
