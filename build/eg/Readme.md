# Sovereignty Summit Egypt 2026 — MicroHack

> Country edition of the **Sovereignty Summit MicroHack** for **Egypt**.
> Generated from `common/` + `countries/eg/overrides/` via
> `tools/render.py`.

## ⚠️ Egypt context — no in-country Azure region

Unlike most editions, **there is no Azure region inside Egypt yet**. The
closest hyperscale region is **UAE North (closest hyperscale region to Egypt)**
(`uaenorth`). This shapes every challenge in this
edition: PDPL- and CBE-regulated data **cannot** simply move to the closest
region — you must combine `uaenorth` for non-regulated
workloads with **Azure Local + Azure Arc** for the regulated tier that has to
stay inside Egypt.

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
- The **Executive Regulations** (Decree 816 of 2025) gave entities until
  **2026-10-31** to come into full compliance with
  PDPL Law 151/2020. From that date the PDPC can fine and license-suspend
  non-compliant data controllers.
- Any transfer of personal data outside Egypt requires a **PDPC cross-border
  permit** in addition to the general processing licence. The destination
  country must be on the PDPC's adequacy list **or** be covered by approved
  standard contractual clauses.
- The **Central Bank of Egypt** (CBE) Cloud Computing Framework adds
  bank-specific obligations on top of PDPL: prior CBE approval for
  outsourcing core banking workloads, mandatory in-country storage of
  customer financial PII, and an exit/repatriation plan.
- Practical pattern: keep core regulated systems on **Azure Local** clusters
  inside Egyptian data centres, projected into Azure via **Azure Arc**, with
  derived analytics in `uaenorth` after PDPC permit.

## Challenges (Egypt edition order)

1. Azure native sovereign controls (Policy, RBAC) — [`challenges/challenge-01.md`](challenges/challenge-01.md)
2. Encryption at rest with CMK — [`challenges/challenge-02.md`](challenges/challenge-02.md)
3. Encryption in transit (TLS) — [`challenges/challenge-03.md`](challenges/challenge-03.md)
4. Confidential VMs — [`challenges/challenge-04.md`](challenges/challenge-04.md)
5. Confidential AKS — [`challenges/challenge-05.md`](challenges/challenge-05.md)
6. Azure Local + Arc — [`challenges/challenge-06.md`](challenges/challenge-06.md)
7. **🇪🇬 PDPC cross-border permit + adequacy guardrails** — [`challenges/challenge-eg-01-pdpc-cross-border-permit.md`](challenges/challenge-eg-01-pdpc-cross-border-permit.md)
8. **🇪🇬 Hybrid CBE-compliant landing zone with Azure Local + Arc** — [`challenges/challenge-eg-02-hybrid-cbe-azure-local.md`](challenges/challenge-eg-02-hybrid-cbe-azure-local.md)

## Attribution

Based on the [Microsoft Sovereign Cloud MicroHack](https://github.com/microsoft/MicroHack/tree/main/03-Azure/01-03-Infrastructure/01_Sovereign_Cloud)
(MIT-licensed) by Jan Egil Ring, Ye Zhang, Murali Rao Yelamanchili and other
Microsoft contributors. Egypt customizations © Sovereignty Summit EG Chapter.
