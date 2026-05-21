# Sovereignty Summit Saudi Arabia 2026 — MicroHack

> Saudi Arabia edition of the **Sovereignty Summit MicroHack** for teams building
> public-sector, critical-national-infrastructure, and SAMA-regulated workloads.

## Saudi Arabia at a glance

| Item | Value |
|---|---|
| Country | Saudi Arabia |
| Primary Azure region | `saudiarabiaeast` (Saudi Arabia East) |
| Exception geo-DR region | `qatarcentral` (Qatar Central) |
| Sovereign-aligned region | `True` |
| Resilience pattern | Three in-country availability zones first; use cross-border DR only by exception. |
| Primary data-protection law | Personal Data Protection Law (PDPL) — Royal Decree M/19 dated 9/2/1443 AH |
| PDPL status | In force since 14 September 2023; the one-year compliance grace period ended on 14 September 2024 |
| Regulatory stack | PDPL + Implementing Regulations, SDAIA Regulation on Personal Data Transfer Outside the Kingdom, SAMA Cyber Security Framework (Rulebook), SAMA cloud computing / third-party requirements (Rulebook §3.4), NCA Essential Cybersecurity Controls (ECC-2:2024), NCA Cloud Cybersecurity Controls (CCC-2:2024), NCA Critical Systems Cybersecurity Controls (CSCC-1:2019) |
| Confidential compute SKUs | Standard_DC2as_v5, Standard_DC4as_v5, Standard_EC2as_v5, Standard_EC4as_v5 |
| Key custody default | `Premium` Key Vault / HSM in `saudiarabiaeast` |
| Sponsor | Microsoft Arabia |

## What is different in the Saudi edition

- **In-country first:** production data, keys, backups, and operational telemetry
  stay in `saudiarabiaeast` by default.
- **Cross-border DR is exceptional:** `qatarcentral` is used only
  when there is a documented regulator-approved disaster-recovery exception.
- **Three regulators matter at once:** SDAIA administers PDPL and transfer rules, NCA sets the national cyber baseline for government and critical sectors, and SAMA layers sector-specific cyber, outsourcing, cloud, audit, and exit obligations onto regulated financial institutions.
- **Two sector stories are emphasized:**
  - **Public sector:** A Saudi Vision 2030 government entity operating a national licensing and permits platform
  - **Financial services:** A SAMA-regulated bank running instant payments and digital-wallet services

## How to use this edition

1. From the repository root, render the attendee pack:
   ```bash
   .venv/bin/python tools/render.py
   ```
2. Start with the core sovereignty labs, then complete the Saudi-specific
   extensions.
3. Use the walkthrough links when you want a guided build, control mapping, or an
   evidence-pack checklist.

## Challenge sequence

1. Azure native sovereign controls (Policy, RBAC) — [`challenges/challenge-01.md`](challenges/challenge-01.md)
2. Encryption at rest with CMK — [`challenges/challenge-02.md`](challenges/challenge-02.md)
3. Encryption in transit (TLS) — [`challenges/challenge-03.md`](challenges/challenge-03.md)
4. Confidential VMs — [`challenges/challenge-04.md`](challenges/challenge-04.md)
5. Confidential AKS — [`challenges/challenge-05.md`](challenges/challenge-05.md)
6. Azure Local + Arc — [`challenges/challenge-06.md`](challenges/challenge-06.md)
7. **🇸🇦 NCA CCC-aligned sovereign landing zone** — [`challenges/challenge-ksa-01-nca-ccc-sovereign-landing-zone.md`](challenges/challenge-ksa-01-nca-ccc-sovereign-landing-zone.md) · [walkthrough](walkthrough/challenge-ksa-01-nca-ccc-sovereign-landing-zone/solution.md)
8. **🇸🇦 SAMA confidential AKS for payments** — [`challenges/challenge-ksa-02-sama-confidential-aks-payments.md`](challenges/challenge-ksa-02-sama-confidential-aks-payments.md) · [walkthrough](walkthrough/challenge-ksa-02-sama-confidential-aks-payments/solution.md)

## Suggested workshop prerequisites

- Azure subscription access with permission to create management groups, Policy
  assignments, Key Vaults, managed identities, networking, AKS, and monitoring.
- Azure CLI, `kubectl`, and `helm`; add `velero` if you want to rehearse the exit
  and repatriation steps in Challenge 8.
- A design decision on whether the organization will use an Azure HSM-backed key
  store or a customer-owned HSM with BYOK import.

## Saudi design assumptions used throughout

- `saudiarabiaeast` is the primary production region.
- `qatarcentral` is **not** treated as a normal active-active
  secondary; it exists only for approved DR exceptions.
- NCA ECC / CCC define the sovereign landing-zone baseline for government and
  critical workloads.
- SAMA overlays cloud-adoption approval, third-party audit rights, incident
  handling, and exit obligations for regulated banks and payments institutions.

## Regulator references

{'name': 'SDAIA / Personal Data Protection resources', 'url': 'https://dgp.sdaia.gov.sa/wps/portal/pdp/knowledgecenter/'}, {'name': 'Saudi Central Bank (SAMA) Rulebook', 'url': 'https://rulebook.sama.gov.sa/en/'}, {'name': 'National Cybersecurity Authority (NCA)', 'url': 'https://nca.gov.sa/en/regulatory-documents/'}

## Attribution

Based on the [Microsoft Sovereign Cloud MicroHack](https://github.com/microsoft/MicroHack/tree/main/03-Azure/01-03-Infrastructure/01_Sovereign_Cloud)
(MIT-licensed) by Jan Egil Ring, Ye Zhang, Murali Rao Yelamanchili and other
Microsoft contributors. Saudi Arabia customizations © Sovereignty Summit KSA
Chapter.
