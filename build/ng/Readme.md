# Sovereignty Summit Nigeria 2026 — MicroHack

> Country edition of the **Sovereignty Summit MicroHack** for **Nigeria**.
> Generated from `common/` + `countries/ng/overrides/` via
> `tools/render.py`.

## ⚠️ Nigeria context — no in-country Azure region

There is **no Azure region inside Nigeria today**. The closest practical Azure
region for this edition is **South Africa North (closest hyperscale region to Nigeria)**
(`southafricanorth`), paired with
**South Africa West** (`southafricawest`).
That means every Nigerian architecture in this repo must be explicit about what
crosses the border and what stays in-country.

### Two valid Nigeria patterns in this edition

1. **Hybrid sovereign path** — keep regulated workloads, raw identifiers,
   detokenisation keys and operational break-glass copies on **Azure Local + Arc
   in Nigeria**, while derived / tokenised workloads use
   `southafricanorth`.
2. **Sovereign public cloud path** — use `southafricanorth` as the
   main hyperscale region, but still apply **allowed-locations pinning**,
   **Premium Key Vault HSM-backed CMK**, **Private Link**, and an
   **in-country tokenisation boundary** for NDPA-restricted fields.

This is deliberate: for countries without an in-country data centre, the answer
is **not** “Azure Local only.” It is either a hybrid pattern or a sovereign
public-cloud pattern with stronger policy, key management and data-splitting.

## Country context

| Item | Value |
|---|---|
| Country | Nigeria |
| In-country Azure region | ❌ none (closest: `southafricanorth`) |
| Paired region | `southafricawest` (South Africa West) |
| Primary data-protection law | Nigeria Data Protection Act 2023 (NDPA) |
| Breach notification window | 72 hours to the NDPC where risk to rights/freedoms exists |
| Cross-border transfer | NDPA ss.41-43 + GAID 2025: document adequacy, an NDPC-approved transfer instrument / SCC-equivalent, or another lawful s.43 basis |
| Major-controller registration | NDPA s.44 + NDPC 14 Feb 2024 guidance |
| Regulatory frameworks in scope | Nigeria Data Protection Act 2023 (NDPA) — ss.24, 32, 40, 41, 42, 43, 44, 65, NDPA General Application and Implementation Directive (GAID) 2025 — DCPMI obligations, cross-border transfer instruments, annual returns and breach workflow detail, NDPC Guidance Notice on Registration of Data Controllers and Data Processors of Major Importance (14 Feb 2024), CBN Risk-Based Cybersecurity Framework and Guidelines for Deposit Money Banks and Payment Service Banks (2024), CBN Guidelines on Shared Services Arrangements for Banks and Other Financial Institutions (outsourcing / approval / audit-rights expectations) |
| Confidential compute SKUs (southafricanorth) | Standard_DC2as_v5, Standard_DC4as_v5, Standard_EC2as_v5, Standard_EC4as_v5 |
| Key Vault SKU | Premium |
| Sponsor | Microsoft Nigeria |

### Scenarios used throughout the challenges
- **Public sector:** National Identity Management Commission (NIMC) identity-verification and citizen-services workload
- **Financial services:** A tier-1 Nigerian bank modernising digital channels under CBN cloud and outsourcing rules

### Nigeria-specific notes
- **NDPA s.40** requires notification to the **NDPC** within
  **72 hours** after awareness of a
  qualifying breach, while affected data subjects must also be informed without
  undue delay where the risk threshold is high.
- **NDPA ss.41-43** and **GAID 2025** make a deployment in
  `southafricanorth` a **cross-border transfer posture by
  default**. Record the destination, legal basis, safeguards, and whether your
  reliance is on adequacy, an NDPC-recognised transfer instrument, or another
  lawful **s.43** condition.
- **NDPA s.44** requires data controllers / processors of major importance to
  register with the **NDPC** and disclose their DPO, categories of data,
  recipients, transfer destinations, and safeguards. The NDPC's **14 Feb 2024**
  guidance makes this especially relevant for government bodies, finance, and
  organisations processing more than **200 data subjects in six months**.
- The **CBN Risk-Based Cybersecurity Framework (2024)** adds bank-specific
  obligations for third-party / cloud risk, monitoring, incident reporting and
  regulatory compliance; the **CBN Shared Services / Outsourcing Guidelines**
  add approval, audit-rights, contract and exit-planning expectations for cloud
  providers.
- Default design rule: if a field would create an NDPA or CBN problem when sent
  cross-border, **tokenise or keep it in Nigeria**. `southafricanorth`
  is for approved public-cloud processing, not for uncontrolled raw-data sprawl.

## Challenges (Nigeria edition order)

1. Azure native sovereign controls (Policy, RBAC) — see [`challenges/challenge-01.md`](challenges/challenge-01.md)
2. Encryption at rest with CMK — [`challenges/challenge-02.md`](challenges/challenge-02.md)
3. Encryption in transit (TLS) — [`challenges/challenge-03.md`](challenges/challenge-03.md)
4. Confidential VMs — [`challenges/challenge-04.md`](challenges/challenge-04.md)
5. Confidential AKS — [`challenges/challenge-05.md`](challenges/challenge-05.md)
6. Azure Local + Arc — [`challenges/challenge-06.md`](challenges/challenge-06.md)
7. **🇳🇬 NDPA cross-border guardrails + NDPC SDCMI registration** — [`challenges/challenge-ng-01-ndpa-cross-border-sdcmi.md`](challenges/challenge-ng-01-ndpa-cross-border-sdcmi.md)
8. **🇳🇬 CBN-compliant hybrid landing zone with Azure Local + Arc** — [`challenges/challenge-ng-02-cbn-hybrid-azure-local.md`](challenges/challenge-ng-02-cbn-hybrid-azure-local.md)
9. **🇳🇬 Sovereign public cloud in Johannesburg with in-country tokenisation boundary** — [`challenges/challenge-ng-03-sovereign-public-cloud-johannesburg.md`](challenges/challenge-ng-03-sovereign-public-cloud-johannesburg.md)

## Attribution

Based on the [Microsoft Sovereign Cloud MicroHack](https://github.com/microsoft/MicroHack/tree/main/03-Azure/01-03-Infrastructure/01_Sovereign_Cloud)
(MIT-licensed) by Jan Egil Ring, Ye Zhang, Murali Rao Yelamanchili and other
Microsoft contributors. Nigeria customizations © Sovereignty Summit NG Chapter.
