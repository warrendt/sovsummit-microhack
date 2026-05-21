# Sovereignty Summit United Arab Emirates 2026 — MicroHack

> Country edition of the **Sovereignty Summit MicroHack** for **United Arab Emirates**.
> Generated from `common/` + `countries/ae/overrides/` via
> `tools/render.py`.

## 🇦🇪 Why the UAE edition is different

The UAE edition is not primarily a "no local region" story. Azure already has
an in-country region in **UAE North**
(`uaenorth`), with paired resilience in
**UAE Central** (`uaecentral`).

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
| Country | United Arab Emirates |
| In-country Azure region | ✅ `uaenorth` (UAE North) |
| Paired Azure region | `uaecentral` (UAE Central) |
| Primary federal law | UAE Federal Decree-Law No. 45 of 2021 Regarding the Protection of Personal Data (PDPL) |
| Executive regulations | Cabinet Decision No. 44 of 2023 (PDPL Executive Regulations, in force) |
| Regulatory frameworks in scope | UAE Federal Decree-Law No. 45 of 2021 Regarding the Protection of Personal Data (PDPL), Cabinet Decision No. 44 of 2023 (Executive Regulations of the PDPL), DIFC Data Protection Law (DIFC Law No. 5 of 2020, as amended by DIFC Laws Amendment Law No. 1 of 2025), ADGM Data Protection Regulations 2021, including the Substantial Public Interest Conditions Rules 2025, CBUAE Outsourcing Regulation and Standards for Banks, CBUAE Consumer Protection Regulation and Consumer Protection Standards, CBUAE Rulebook guidance for Financial Institutions Adopting Enabling Technologies (Cloud Computing), UAE Information Assurance baseline (formerly NESA / IAS, now under national assurance programmes), Federal Law No. 2 of 2019 Concerning the Use of Information and Communication Technology in Health Fields, DHA health-data protection, sharing and access-control policies for Dubai-licensed health entities |
| Confidential compute SKUs | Standard_DC2as_v5, Standard_DC4as_v5, Standard_EC2as_v5, Standard_EC4as_v5 |
| Key Vault SKU | Premium |
| Sponsor | Microsoft UAE |

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
  CMKs, logs, backups and audit evidence in `uaenorth` or
  `uaecentral` unless an approved exception says otherwise.
- **Layer sector rules on top of the base regime.** Banking, health and telecom
  controls add obligations; they do not replace the main perimeter decision.

## Scenarios used throughout the challenges

- **Public sector / shared services:** A government-related citizen-services platform integrating with onshore entities, a DIFC bank and an ADGM analytics provider
- **Financial services:** A CBUAE-licensed UAE bank modernising digital onboarding, payments and fraud analytics

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
