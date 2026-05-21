# ${country.summit_edition} — MicroHack

> Country edition of the **Sovereignty Summit MicroHack** for **${country.name}**.
> Generated from `common/` + `countries/${country.iso2}/overrides/` via
> `tools/render.py`.

## Qatar context

| Item | Value |
|---|---|
| Country | ${country.name} |
| Primary Azure region | `${country.azure.primary_region}` (${country.azure.primary_region_display}) |
| Official Azure pair | ${country.azure.official_region_pair} |
| Customer-selected DR region for this edition | `${country.azure.paired_region}` (${country.azure.paired_region_display}) |
| Primary data-protection law | ${country.regulatory.primary_law} |
| Executive regulations | ${country.regulatory.executive_regulations} |
| Data protection regulator | ${country.regulatory.primary_regulator} |
| Frameworks in scope | ${country.regulatory.frameworks} |
| NIA classification scheme | ${country.regulatory.classification_scheme} |
| Confidential compute note | ${country.azure.confidential_compute_note} |
| Key Vault SKU | ${country.azure.cmk_hsm_sku} |
| Sponsor | ${country.sponsor.primary} |

### Scenarios used throughout the challenges
- **Public sector:** ${country.scenarios.public_sector_tenant}
- **Financial services:** ${country.scenarios.financial_tenant}
- **QFC contrast:** ${country.scenarios.qfc_tenant}

### Qatar-specific notes
- **${country.azure.primary_region_display}** is an in-country Azure region, so the default pattern is to keep regulated production data in `${country.azure.primary_region}`.
- Microsoft documents **`${country.azure.primary_region}` as a nonpaired region**. This edition therefore treats `${country.azure.paired_region}` as a **customer-chosen DR / transfer region**, not an official Azure pair.
- Under **${country.regulatory.primary_law}** and **${country.regulatory.executive_regulations}**, ${country.regulatory.cross_border_rule}
- The **NCSA NIA Policy v2.0** classification ladder — ${country.regulatory.classification_scheme} — is used in this edition as the tagging taxonomy that drives Azure Policy decisions.
- For QCB-regulated workloads, cloud use requires formal governance, provider due diligence, auditability, exit planning and strong key-management controls. For QFC firms, ${country.regulatory.qfc_contrast}
- ${country.azure.confidential_compute_note}

## Challenges (Qatar edition order)

1. Azure native sovereign controls (Policy, RBAC) — [`challenges/challenge-01.md`](challenges/challenge-01.md)
2. Encryption at rest with CMK — [`challenges/challenge-02.md`](challenges/challenge-02.md)
3. Encryption in transit (TLS) — [`challenges/challenge-03.md`](challenges/challenge-03.md)
4. Confidential VMs — [`challenges/challenge-04.md`](challenges/challenge-04.md)
5. Confidential AKS — [`challenges/challenge-05.md`](challenges/challenge-05.md)
6. Azure Local + Arc — [`challenges/challenge-06.md`](challenges/challenge-06.md)
7. **🇶🇦 PDPPL + NIA classification guardrails** — [`challenges/challenge-qa-01-pdppl-nia-classification.md`](challenges/challenge-qa-01-pdppl-nia-classification.md)
8. **🇶🇦 QCB payments landing zone in Qatar Central** — [`challenges/challenge-qa-02-qcb-payments-landing-zone.md`](challenges/challenge-qa-02-qcb-payments-landing-zone.md)

## Attribution

Based on the [Microsoft Sovereign Cloud MicroHack](https://github.com/microsoft/MicroHack/tree/main/03-Azure/01-03-Infrastructure/01_Sovereign_Cloud)
(MIT-licensed) by Jan Egil Ring, Ye Zhang, Murali Rao Yelamanchili and other
Microsoft contributors. Qatar customizations © Sovereignty Summit QA Chapter.
