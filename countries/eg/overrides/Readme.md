# ${country.summit_edition} — MicroHack

> Country edition of the **Sovereignty Summit MicroHack** for **${country.name}**.
> Generated from `common/` + `countries/${country.iso2}/overrides/` via
> `tools/render.py`.

## ⚠️ Egypt context — no in-country Azure region

Unlike most editions, **there is no Azure region inside Egypt yet**. The
closest hyperscale region is **${country.azure.primary_region_display}**
(`${country.azure.primary_region}`). The Egypt edition therefore teaches **two
honest patterns in parallel**:

1. **Sovereign public cloud in `${country.azure.primary_region}` / `${country.azure.paired_region}`** for data that PDPL does **not** require to stay in Egypt, using strict region pinning, CMK in Premium Key Vault, Private Link, and customer-controlled tokenisation.
2. **Azure Local + Azure Arc inside Egypt** for data that PDPL, CBE policy, or your own risk assessment says must remain physically in-country.

The core design rule is simple: **do not assume Azure Local is the only answer just because Egypt lacks a data centre; do not assume `${country.azure.primary_region}` is acceptable for all data just because it is the closest region.**

## Country context

| Item | Value |
|---|---|
| Country | ${country.name} |
| In-country Azure region | ❌ none (closest: `${country.azure.primary_region}`) |
| Paired region | `${country.azure.paired_region}` (${country.azure.paired_region_display}) |
| Primary data-protection law | ${country.regulatory.primary_law} |
| PDPL full-enforcement date | ${country.regulatory.enforcement_date} |
| Breach notification window | ${country.regulatory.breach_notification_hours} hours to the PDPC |
| Cross-border transfer | Requires PDPC permit + adequacy assessment + data-subject consent |
| Regulatory frameworks in scope | ${country.regulatory.frameworks} |
| Confidential compute SKUs (UAE North) | ${country.azure.confidential_compute_skus} |
| Key Vault SKU | ${country.azure.cmk_hsm_sku} |
| Sponsor | ${country.sponsor.primary} |

### Scenarios used throughout the challenges
- **Public sector:** ${country.scenarios.public_sector_tenant}
- **Financial services:** ${country.scenarios.financial_tenant}

### Egypt-specific notes
- The **Executive Regulations** (Ministerial Decree 816 of 2025) took effect on
  **1 Nov 2025** and created a **one-year grace period**, so full enforcement is
  expected from **1 Nov 2026** (practically: the compliance countdown ends on
  **${country.regulatory.enforcement_date}**).
- Cross-border transfers remain **permit-led**: a controller / processor must be
  licensed with the **PDPC**, and a transfer outside Egypt requires a **separate
  PDPC permit or approval**, with destination, purpose, data categories and
  safeguards documented.
- Breach handling is now explicit in the Regulations: notify the **PDPC within
  ${country.regulatory.breach_notification_hours} hours** of awareness, then notify affected individuals within **three working days** where required.
- The **Central Bank of Egypt** (CBE) Cloud Computing Framework adds
  bank-specific obligations on top of PDPL: prior CBE approval for
  outsourcing core banking workloads, mandatory in-country handling for the
  most sensitive customer financial data, and an exit / repatriation plan.
- Practical pattern: keep token vaults, re-identification services, and any
  data that your legal position says must remain in Egypt on **Azure Local**;
  place permitted or derived workloads in `${country.azure.primary_region}` with
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
