# Sovereignty Summit United Arab Emirates 2026 — MicroHack

> Country edition of the **Sovereignty Summit MicroHack** for **United Arab Emirates**.
> Generated from `common/` + `countries/ae/overrides/` via
> `tools/render.py`.

## 🇦🇪 UAE context — in-country Azure region + overlapping legal perimeters

This edition follows the **in-country region** pattern: Azure workloads can stay
inside the UAE in **UAE North**
(`uaenorth`) with paired resilience in
**UAE Central** (`uaecentral`).

The sovereignty wrinkle is **jurisdiction, not region scarcity**:

- **Onshore UAE entities** generally fall under the federal **PDPL** and its
  Executive Regulations.
- **DIFC** and **ADGM** each operate their own data-protection regimes.
- Sector overlays still matter: **CBUAE** for licensed financial institutions,
  **UAE IAS** for assurance baselines, and **Dubai health-data rules** for
  Dubai health workloads.
- Because confidential-compute SKUs are available in `uaenorth`,
  this edition can use **AKS confidential node pools + Premium Key Vault CMK**
  without leaving the country.

## Country context

| Item | Value |
|---|---|
| Country | United Arab Emirates |
| In-country Azure region | ✅ `uaenorth` (UAE North) |
| Paired Azure region | `uaecentral` (UAE Central) |
| Primary data-protection law | UAE Federal Decree-Law No. 45 of 2021 on the Protection of Personal Data (PDPL) |
| Executive regulations | Cabinet Decision No. 44 of 2023 (Executive Regulations of the PDPL) |
| Regulatory frameworks in scope | UAE Federal PDPL (Federal Decree-Law No. 45 of 2021), PDPL Executive Regulations (Cabinet Decision No. 44 of 2023), DIFC Data Protection Law (DIFC Law No. 5 of 2020), ADGM Data Protection Regulations 2021, UAE Information Assurance Standards (TDRA / formerly NESA), CBUAE Consumer Protection Regulation and Consumer Protection Standards, Dubai Health Data Law (Dubai Law No. 13 of 2019 Regulating ICT in Health Fields) |
| Confidential compute SKUs | Standard_DC2as_v5, Standard_DC4as_v5, Standard_EC2as_v5, Standard_EC4as_v5 |
| Key Vault SKU | Premium |
| Sponsor | Microsoft UAE |

### Scenarios used throughout the challenges
- **Public sector:** An Abu Dhabi government entity modernising a citizen-services and case-management platform
- **Financial services:** A DIFC-licensed bank modernising digital onboarding, payments and risk analytics

### UAE-specific notes
- The key design decision is to classify each workload into the right
  **regulatory perimeter** (`federal-pdpl`, `difc`, `adgm`, and sector-specific
  overlays) before you worry about normal platform controls.
- DIFC and ADGM keep their own data-protection regimes, so jurisdiction depends on where the controller or processor is established and which free-zone legal perimeter the workload serves.
- For the banking scenario, combine **DIFC Law No. 5 of 2020** with the
  **CBUAE Consumer Protection Regulation / Standards** and UAE IAS controls for
  key management, auditability and outsourcing oversight.
- For public-sector and health workloads, keep telemetry, backups and customer-
  managed keys in `uaenorth` or
  `uaecentral` unless a documented legal exception says
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
