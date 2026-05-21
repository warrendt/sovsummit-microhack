# ${country.summit_edition} — MicroHack

> Country edition of the **Sovereignty Summit MicroHack** for **${country.name}**.
> Generated from `common/` + `countries/${country.iso2}/overrides/` via
> `tools/render.py`.

## ⚠️ Nigeria context — no in-country Azure region

There is **no Azure region inside Nigeria today**. The closest practical Azure
region for this edition is **${country.azure.primary_region_display}**
(`${country.azure.primary_region}`). That means every design has to separate:

- **Regulated data that must stay in Nigeria** — citizen identity data, KYC,
  BVN-linked records, cardholder data, and core banking records.
- **Derived / non-regulated data** that can be lawfully transferred to
  `${country.azure.primary_region}` after satisfying NDPA cross-border rules.

The country edition therefore follows the same pattern many Nigerian teams use in
practice: **Azure Local + Azure Arc inside Nigeria for the regulated tier**, and
`${country.azure.primary_region}` only for tokenised, de-identified or otherwise
approved workloads.

## Country context

| Item | Value |
|---|---|
| Country | ${country.name} |
| In-country Azure region | ❌ none (closest: `${country.azure.primary_region}`) |
| Paired region | `${country.azure.paired_region}` (${country.azure.paired_region_display}) |
| Primary data-protection law | ${country.regulatory.primary_law} |
| Breach notification window | ${country.regulatory.breach_notification_hours} hours to the NDPC where risk to rights/freedoms exists |
| Cross-border transfer | NDPA ss.41-43: adequacy or another lawful transfer basis must be recorded |
| Major-controller registration | NDPA s.44 + NDPC 14 Feb 2024 guidance |
| Regulatory frameworks in scope | ${country.regulatory.frameworks} |
| Confidential compute SKUs (${country.azure.primary_region}) | ${country.azure.confidential_compute_skus} |
| Key Vault SKU | ${country.azure.cmk_hsm_sku} |
| Sponsor | ${country.sponsor.primary} |

### Scenarios used throughout the challenges
- **Public sector:** ${country.scenarios.public_sector_tenant}
- **Financial services:** ${country.scenarios.financial_tenant}

### Nigeria-specific notes
- **NDPA s.41** blocks cross-border transfers unless the destination has
  adequate protection (per **s.42**) or another basis in **s.43** applies. A
  Nigerian workload in `${country.azure.primary_region}` is therefore a
  cross-border transfer by default.
- **NDPA s.44** requires data controllers / processors of major importance to
  register with the **NDPC** and disclose their DPO, data categories,
  recipients, destination countries, and safeguards. The NDPC's **14 Feb 2024**
  guidance makes this especially relevant for public-sector bodies, finance, and
  organisations processing more than 200 data subjects in six months.
- **NDPA s.32** requires a DPO for a controller of major importance, and
  **s.40(2)** requires notification to the NDPC within
  **${country.regulatory.breach_notification_hours} hours** after becoming aware
  of a qualifying breach.
- The **CBN Risk-Based Cybersecurity Framework (2024)** adds bank-specific
  obligations for third-party / cloud risk, monitoring, incident reporting and
  regulatory compliance; the **CBN Shared Services / Outsourcing Guidelines**
  add approval, audit-rights, contract and exit-planning expectations for cloud
  providers.
- Practical pattern: keep regulated PII and transaction-processing systems on
  **Azure Local in Nigeria**, project them into Azure through **Azure Arc**, and
  send only tokenised / de-identified analytics to `${country.azure.primary_region}`.

## Challenges (Nigeria edition order)

1. Azure native sovereign controls (Policy, RBAC) — see [`challenges/challenge-01.md`](challenges/challenge-01.md)
2. Encryption at rest with CMK — [`challenges/challenge-02.md`](challenges/challenge-02.md)
3. Encryption in transit (TLS) — [`challenges/challenge-03.md`](challenges/challenge-03.md)
4. Confidential VMs — [`challenges/challenge-04.md`](challenges/challenge-04.md)
5. Confidential AKS — [`challenges/challenge-05.md`](challenges/challenge-05.md)
6. Azure Local + Arc — [`challenges/challenge-06.md`](challenges/challenge-06.md)
7. **🇳🇬 NDPA cross-border guardrails + NDPC SDCMI registration** — [`challenges/challenge-ng-01-ndpa-cross-border-sdcmi.md`](challenges/challenge-ng-01-ndpa-cross-border-sdcmi.md)
8. **🇳🇬 CBN-compliant hybrid landing zone with Azure Local + Arc** — [`challenges/challenge-ng-02-cbn-hybrid-azure-local.md`](challenges/challenge-ng-02-cbn-hybrid-azure-local.md)

## Attribution

Based on the [Microsoft Sovereign Cloud MicroHack](https://github.com/microsoft/MicroHack/tree/main/03-Azure/01-03-Infrastructure/01_Sovereign_Cloud)
(MIT-licensed) by Jan Egil Ring, Ye Zhang, Murali Rao Yelamanchili and other
Microsoft contributors. Nigeria customizations © Sovereignty Summit NG Chapter.
