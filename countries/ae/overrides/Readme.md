# ${country.summit_edition} — MicroHack

> Country edition of the **Sovereignty Summit MicroHack** for **${country.name}**.
> Generated from `common/` + `countries/${country.iso2}/overrides/` via
> `tools/render.py`.

## 🇦🇪 Why the UAE edition is different

The UAE edition is not primarily a "no local region" story. Azure already has
an in-country region in **${country.azure.primary_region_display}**
(`${country.azure.primary_region}`), with paired resilience in
**${country.azure.paired_region_display}** (`${country.azure.paired_region}`).

The real challenge is **legal perimeter selection**:

1. **Federal PDPL + Executive Regulations** for onshore private-sector entities.
2. **DIFC Data Protection Law** for DIFC-established processing.
3. **ADGM Data Protection Regulations 2021** for ADGM-established processing.

On top of that, sector regulators still matter:

- **CBUAE** for banks and regulated financial institutions.
- **TDRA / national assurance baselines** for telecom / information assurance.
- **Federal + Dubai health rules / DHA policies** for health workloads.

In other words: the UAE challenge is usually **"which regulator applies?"**
before it is **"which Azure control do I turn on?"**

## What this edition assumes

| Item | Value |
|---|---|
| Country | ${country.name} |
| In-country Azure region | ✅ `${country.azure.primary_region}` (${country.azure.primary_region_display}) |
| Paired Azure region | `${country.azure.paired_region}` (${country.azure.paired_region_display}) |
| Primary federal law | ${country.regulatory.primary_law} |
| Executive regulations | ${country.regulatory.executive_regulations} |
| Regulatory frameworks in scope | ${country.regulatory.frameworks} |
| Confidential compute SKUs | ${country.azure.confidential_compute_skus} |
| Key Vault SKU | ${country.azure.cmk_hsm_sku} |
| Sponsor | ${country.sponsor.primary} |

## How to use this UAE edition

1. Work through Challenges 1–6 to refresh the core Azure sovereignty controls.
2. Use **Challenge AE-01** to decide the legal perimeter for each workload or
   shared service.
3. Use **Challenge AE-02** to implement a UAE-banking landing zone that is
   realistic for a **CBUAE-regulated** institution.
4. Render the finished content with `tools/render.py` if you customize anything.

## UAE-specific design rules of thumb

- **Start with the legal establishment.** Ask where the controller / processor is
  established before you design the landing zone.
- **Do not confuse Azure region with legal perimeter.** DIFC, ADGM and onshore
  UAE entities can all use the same physical region and still be governed by
  different rules.
- **Treat government data carefully.** Federal PDPL does not automatically cover
  every government-authority processing case; some public-sector workloads need
  a separate legal basis or exception path.
- **Keep key custody and evidence in-country.** For regulated workloads, store
  CMKs, logs, backups and audit evidence in `${country.azure.primary_region}` or
  `${country.azure.paired_region}` unless an approved exception says otherwise.
- **Layer sector rules on top of the base regime.** Banking, health and telecom
  controls add obligations; they do not replace the main perimeter decision.

## Scenarios used throughout the challenges

- **Public sector / shared services:** ${country.scenarios.public_sector_tenant}
- **Financial services:** ${country.scenarios.financial_tenant}

## Challenges (UAE edition order)

1. Azure native sovereign controls (Policy, RBAC) — [`challenges/challenge-01.md`](challenges/challenge-01.md)
2. Encryption at rest with CMK — [`challenges/challenge-02.md`](challenges/challenge-02.md)
3. Encryption in transit (TLS) — [`challenges/challenge-03.md`](challenges/challenge-03.md)
4. Confidential VMs — [`challenges/challenge-04.md`](challenges/challenge-04.md)
5. Confidential AKS — [`challenges/challenge-05.md`](challenges/challenge-05.md)
6. Azure Local + Arc — [`challenges/challenge-06.md`](challenges/challenge-06.md)
7. **🇦🇪 Jurisdiction routing across federal PDPL, DIFC and ADGM** — [`challenges/challenge-ae-01-jurisdiction-routing.md`](challenges/challenge-ae-01-jurisdiction-routing.md)
8. **🇦🇪 Confidential AKS landing zone for a CBUAE-regulated bank** — [`challenges/challenge-ae-02-confidential-banking.md`](challenges/challenge-ae-02-confidential-banking.md)

## External references

- [UAE Government data protection overview](https://u.ae/en/about-the-uae/digital-uae/data/data-protection-laws)
- [UAE Data Office](https://u.ae/en/about-the-uae/digital-uae/data/data-office)
- [DIFC data protection](https://www.difc.ae/business/laws-regulations/data-protection/)
- [ADGM Office of Data Protection](https://www.adgm.com/operating-in-adgm/office-of-data-protection)
- [CBUAE Rulebook](https://rulebook.centralbank.ae/)
- [TDRA](https://tdra.gov.ae/)
- [Dubai Health Authority](https://www.dha.gov.ae/)

## Attribution

Based on the [Microsoft Sovereign Cloud MicroHack](https://github.com/microsoft/MicroHack/tree/main/03-Azure/01-03-Infrastructure/01_Sovereign_Cloud)
(MIT-licensed) by Jan Egil Ring, Ye Zhang, Murali Rao Yelamanchili and other
Microsoft contributors. UAE customizations © Sovereignty Summit UAE Chapter.
