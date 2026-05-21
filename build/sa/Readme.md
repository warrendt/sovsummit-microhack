# Sovereignty Summit Saudi Arabia 2026 — MicroHack

> Country edition of the **Sovereignty Summit MicroHack** for **Saudi Arabia**.
> Generated from `common/` + `countries/sa/overrides/` via
> `tools/render.py`.

## Saudi Arabia context

| Item | Value |
|---|---|
| Country | Saudi Arabia |
| Primary Azure region | `saudiarabiaeast` (Saudi Arabia East) |
| Paired region used in this edition | `qatarcentral` (Qatar Central) |
| Sovereign-aligned region | `True` |
| Resilience pattern | Three in-country availability zones first; use cross-border DR only by exception. |
| Primary data-protection law | Personal Data Protection Law (PDPL) — Royal Decree M/19 of 1443 AH |
| PDPL status | In force with implementing regulations since September 2024 |
| Regulator split | SDAIA governs personal data, NCA sets national cyber controls for government and critical sectors, and SAMA adds sector-specific cloud and cyber obligations for regulated financial institutions. |
| Regulatory frameworks in scope | PDPL + Implementing Regulations, SDAIA Regulation on Personal Data Transfer Outside the Kingdom, SAMA Cyber Security Framework v1.0, NCA Essential Cybersecurity Controls (ECC-1:2018), NCA Cloud Cybersecurity Controls (CCC-1:2020), NCA Critical Systems Cybersecurity Controls (CSCC-1:2019) |
| Confidential compute SKUs | Standard_DC2as_v5, Standard_DC4as_v5, Standard_EC2as_v5, Standard_EC4as_v5 |
| Key Vault SKU | Premium |
| Sponsor | Microsoft Arabia |

### Scenarios used throughout the challenges
- **Public sector:** A Saudi Vision 2030 government entity operating a national licensing and permits platform
- **Financial services:** A SAMA-regulated bank running instant payments and digital-wallet services

### Saudi-specific notes
- Microsoft publicly positions **Saudi Arabia East** as the
  in-country Azure region for Saudi data residency, low latency, and
  sovereign-ready cloud adoption aligned to Vision 2030.
- The public Azure regions list does **not** yet show a formal region pair for
  `saudiarabiaeast`. For this edition we use
  **Qatar Central** as the most plausible geo-DR target
  because it is the nearest mature Gulf region that still keeps recovery inside
  the wider GCC neighbourhood. Treat this as a **design assumption**, not an
  official Microsoft pairing.
- Default resilience for regulated workloads should stay **inside the Kingdom**:
  use the three availability zones in `saudiarabiaeast` first,
  and only replicate to `qatarcentral` after a documented
  Transfers outside the Kingdom require a lawful basis, a transfer risk assessment, and an SDAIA-approved safeguard mechanism such as adequacy, SCCs, BCRs, or another permitted exception.
- SDAIA governs personal data, NCA sets national cyber controls for government and critical sectors, and SAMA adds sector-specific cloud and cyber obligations for regulated financial institutions.
- For government and critical-infrastructure workloads, **NCA ECC / CCC /
  CSCC** drive the landing-zone baseline. For banks and payments, **SAMA** adds
  outsourcing, incident-response, audit, and exit/repatriation expectations on
  top of PDPL.

## Challenges (Saudi Arabia edition order)

1. Azure native sovereign controls (Policy, RBAC) — [`challenges/challenge-01.md`](challenges/challenge-01.md)
2. Encryption at rest with CMK — [`challenges/challenge-02.md`](challenges/challenge-02.md)
3. Encryption in transit (TLS) — [`challenges/challenge-03.md`](challenges/challenge-03.md)
4. Confidential VMs — [`challenges/challenge-04.md`](challenges/challenge-04.md)
5. Confidential AKS — [`challenges/challenge-05.md`](challenges/challenge-05.md)
6. Azure Local + Arc — [`challenges/challenge-06.md`](challenges/challenge-06.md)
7. **🇸🇦 NCA CCC-aligned sovereign landing zone** — [`challenges/challenge-ksa-01-nca-ccc-sovereign-landing-zone.md`](challenges/challenge-ksa-01-nca-ccc-sovereign-landing-zone.md)
8. **🇸🇦 SAMA confidential AKS for payments** — [`challenges/challenge-ksa-02-sama-confidential-aks-payments.md`](challenges/challenge-ksa-02-sama-confidential-aks-payments.md)

## Attribution

Based on the [Microsoft Sovereign Cloud MicroHack](https://github.com/microsoft/MicroHack/tree/main/03-Azure/01-03-Infrastructure/01_Sovereign_Cloud)
(MIT-licensed) by Jan Egil Ring, Ye Zhang, Murali Rao Yelamanchili and other
Microsoft contributors. Saudi Arabia customizations © Sovereignty Summit KSA
Chapter.
