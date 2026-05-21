# ${country.summit_edition} — MicroHack

> Country edition of the **Sovereignty Summit MicroHack** for **${country.name}**.
> Generated from `common/` + `countries/${country.iso2}/overrides/` via
> `tools/render.py`.

## 🇦🇪 UAE context — in-country Azure region + overlapping legal perimeters

This edition follows the **in-country region** pattern: Azure workloads can stay
inside the UAE in **${country.azure.primary_region_display}**
(`${country.azure.primary_region}`) with paired resilience in
**${country.azure.paired_region_display}** (`${country.azure.paired_region}`).

The sovereignty wrinkle is **jurisdiction, not region scarcity**:

- **Onshore UAE entities** generally fall under the federal **PDPL** and its
  Executive Regulations.
- **DIFC** and **ADGM** each operate their own data-protection regimes.
- Sector overlays still matter: **CBUAE** for licensed financial institutions,
  **UAE IAS** for assurance baselines, and **Dubai health-data rules** for
  Dubai health workloads.
- Because confidential-compute SKUs are available in `${country.azure.primary_region}`,
  this edition can use **AKS confidential node pools + Premium Key Vault CMK**
  without leaving the country.

## Country context

| Item | Value |
|---|---|
| Country | ${country.name} |
| In-country Azure region | ✅ `${country.azure.primary_region}` (${country.azure.primary_region_display}) |
| Paired Azure region | `${country.azure.paired_region}` (${country.azure.paired_region_display}) |
| Primary data-protection law | ${country.regulatory.primary_law} |
| Executive regulations | ${country.regulatory.executive_regulations} |
| Regulatory frameworks in scope | ${country.regulatory.frameworks} |
| Confidential compute SKUs | ${country.azure.confidential_compute_skus} |
| Key Vault SKU | ${country.azure.cmk_hsm_sku} |
| Sponsor | ${country.sponsor.primary} |

### Scenarios used throughout the challenges
- **Public sector:** ${country.scenarios.public_sector_tenant}
- **Financial services:** ${country.scenarios.financial_tenant}

### UAE-specific notes
- The key design decision is to classify each workload into the right
  **regulatory perimeter** (`federal-pdpl`, `difc`, `adgm`, and sector-specific
  overlays) before you worry about normal platform controls.
- ${country.regulatory.free_zone_carveout}
- For the banking scenario, combine **DIFC Law No. 5 of 2020** with the
  **CBUAE Consumer Protection Regulation / Standards** and UAE IAS controls for
  key management, auditability and outsourcing oversight.
- For public-sector and health workloads, keep telemetry, backups and customer-
  managed keys in `${country.azure.primary_region}` or
  `${country.azure.paired_region}` unless a documented legal exception says
  otherwise.

## Challenges (UAE edition order)

1. Azure native sovereign controls (Policy, RBAC) — [`challenges/challenge-01.md`](challenges/challenge-01.md)
2. Encryption at rest with CMK — [`challenges/challenge-02.md`](challenges/challenge-02.md)
3. Encryption in transit (TLS) — [`challenges/challenge-03.md`](challenges/challenge-03.md)
4. Confidential VMs — [`challenges/challenge-04.md`](challenges/challenge-04.md)
5. Confidential AKS — [`challenges/challenge-05.md`](challenges/challenge-05.md)
6. Azure Local + Arc — [`challenges/challenge-06.md`](challenges/challenge-06.md)
7. **🇦🇪 Onshore PDPL vs DIFC/ADGM jurisdiction routing** — [`challenges/challenge-ae-01-jurisdiction-routing.md`](challenges/challenge-ae-01-jurisdiction-routing.md)
8. **🇦🇪 Confidential computing for a DIFC-licensed bank** — [`challenges/challenge-ae-02-confidential-banking.md`](challenges/challenge-ae-02-confidential-banking.md)

## Attribution

Based on the [Microsoft Sovereign Cloud MicroHack](https://github.com/microsoft/MicroHack/tree/main/03-Azure/01-03-Infrastructure/01_Sovereign_Cloud)
(MIT-licensed) by Jan Egil Ring, Ye Zhang, Murali Rao Yelamanchili and other
Microsoft contributors. UAE customizations © Sovereignty Summit UAE Chapter.
