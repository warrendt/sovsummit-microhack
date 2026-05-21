# Sovereignty Summit Nigeria 2026 — MicroHack

> Country edition of the **Sovereignty Summit MicroHack** for **Nigeria**.
> Generated from `common/` + `countries/ng/overrides/` via
> `tools/render.py`.

## ⚠️ Nigeria context — no in-country Azure region

There is **no Azure region inside Nigeria today**. The closest practical Azure
region for this edition is **South Africa North (closest hyperscale region to Nigeria)**
(`southafricanorth`). That means every design has to separate:

- **Regulated data that must stay in Nigeria** — citizen identity data, KYC,
  BVN-linked records, cardholder data, and core banking records.
- **Derived / non-regulated data** that can be lawfully transferred to
  `southafricanorth` after satisfying NDPA cross-border rules.

The country edition therefore follows the same pattern many Nigerian teams use in
practice: **Azure Local + Azure Arc inside Nigeria for the regulated tier**, and
`southafricanorth` only for tokenised, de-identified or otherwise
approved workloads.

## Country context

| Item | Value |
|---|---|
| Country | Nigeria |
| In-country Azure region | ❌ none (closest: `southafricanorth`) |
| Paired region | `southafricawest` (South Africa West) |
| Primary data-protection law | Nigeria Data Protection Act 2023 (NDPA) |
| Breach notification window | 72 hours to the NDPC where risk to rights/freedoms exists |
| Cross-border transfer | NDPA ss.41-43: adequacy or another lawful transfer basis must be recorded |
| Major-controller registration | NDPA s.44 + NDPC 14 Feb 2024 guidance |
| Regulatory frameworks in scope | Nigeria Data Protection Act 2023 (NDPA) — ss.24, 32, 40, 41, 42, 43, 44, 65, Nigeria Data Protection Regulation 2019 (NDPR) + NITDA implementation framework, NDPC Guidance Notice on Registration of Data Controllers and Data Processors of Major Importance (14 Feb 2024), CBN Risk-Based Cybersecurity Framework and Guidelines for Deposit Money Banks and Payment Service Banks (2024), CBN Guidelines on Shared Services Arrangements for Banks and Other Financial Institutions (cloud / outsourcing approval) |
| Confidential compute SKUs (southafricanorth) | Standard_DC2as_v5, Standard_DC4as_v5, Standard_EC2as_v5, Standard_EC4as_v5 |
| Key Vault SKU | Premium |
| Sponsor | Microsoft Nigeria |

### Scenarios used throughout the challenges
- **Public sector:** National Identity Management Commission (NIMC) identity-verification and citizen-services workload
- **Financial services:** A tier-1 Nigerian bank modernising digital channels under CBN cloud and outsourcing rules

### Nigeria-specific notes
- **NDPA s.41** blocks cross-border transfers unless the destination has
  adequate protection (per **s.42**) or another basis in **s.43** applies. A
  Nigerian workload in `southafricanorth` is therefore a
  cross-border transfer by default.
- **NDPA s.44** requires data controllers / processors of major importance to
  register with the **NDPC** and disclose their DPO, data categories,
  recipients, destination countries, and safeguards. The NDPC's **14 Feb 2024**
  guidance makes this especially relevant for public-sector bodies, finance, and
  organisations processing more than 200 data subjects in six months.
- **NDPA s.32** requires a DPO for a controller of major importance, and
  **s.40(2)** requires notification to the NDPC within
  **72 hours** after becoming aware
  of a qualifying breach.
- The **CBN Risk-Based Cybersecurity Framework (2024)** adds bank-specific
  obligations for third-party / cloud risk, monitoring, incident reporting and
  regulatory compliance; the **CBN Shared Services / Outsourcing Guidelines**
  add approval, audit-rights, contract and exit-planning expectations for cloud
  providers.
- Practical pattern: keep regulated PII and transaction-processing systems on
  **Azure Local in Nigeria**, project them into Azure through **Azure Arc**, and
  send only tokenised / de-identified analytics to `southafricanorth`.

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
