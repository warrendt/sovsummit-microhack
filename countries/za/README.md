# Sovereignty Summit South Africa 2026 — MicroHack

> Country edition of the **Sovereignty Summit MicroHack** for **South Africa**.
> This is the reference implementation — fully self-contained, tested, and the
> blueprint other country folders copy from.

## Country context

| Item | Value |
|---|---|
| Country | South Africa |
| Primary Azure region | `southafricanorth` (South Africa North) |
| Paired Azure region | `southafricawest` (South Africa West) |
| Primary data-protection law | POPIA |
| Regulatory frameworks in scope | POPIA (Protection of Personal Information Act, 2013), SARB Directive 3/2018 (cloud computing & offshoring of data), FSCA Joint Standard 2 of 2024 (cybersecurity & cyber resilience), NCA (National Credit Act) |
| Confidential compute SKUs | Standard_DC2as_v5, Standard_EC2as_v5 |
| Key Vault SKU | Premium |
| Sponsor | Microsoft South Africa |

### Scenarios used throughout the challenges
- **Public sector:** Department of Home Affairs (DHA) digital identity workload
- **Financial services:** A South African tier-1 retail bank issuing virtual cards

### South Africa–specific notes
- All workload data (including backups and diagnostic data) must remain inside
  South Africa unless an explicit cross-border transfer assessment has been
  performed under **POPIA s.72**.
- Financial-sector workloads are additionally governed by **SARB Directive
  3/2018** on cloud computing and the offshoring of data.
- Customer-managed keys live in a **Premium Key Vault** (HSM-backed) in
  `southafricanorth` with geo-replication to
  `southafricawest`.

## Challenges

In this country edition the following challenges run in order:

| # | Challenge                                       | Brief                                                    | Walkthrough |
|---|-------------------------------------------------|----------------------------------------------------------|-------------|
| 1 | [Azure-native sovereign controls (Policy, RBAC)](challenges/challenge-01.md) | Build a POPIA-aligned policy initiative + RBAC role | [Solution](walkthrough/challenge-01/solution-01.md) |
| 2 | [Encryption at rest with CMK](challenges/challenge-02.md)                    | Premium Key Vault + BYOK on Storage                 | [Solution](walkthrough/challenge-02/solution-02.md) |
| 3 | [Encryption in transit (TLS)](challenges/challenge-03.md)                    | TLS 1.2/1.3 enforcement across services             | [Solution](walkthrough/challenge-03/solution-03.md) |
| 4 | [Confidential VMs](challenges/challenge-04.md)                                | DCasv5 + Azure Attestation for bank payroll         | [Solution](walkthrough/challenge-04/solution-04.md) · [Portal guide](walkthrough/challenge-04/portal-guide.md) |
| 5 | [Confidential AKS](challenges/challenge-05.md)                                | Confidential node pool for fraud-detection inference | [Solution](walkthrough/challenge-05/solution-05.md) · [Portal guide](walkthrough/challenge-05/portal-guide.md) |
| 6 | [Azure Local + Arc](challenges/challenge-06.md)                               | ArcBox + LocalBox sovereignty story                  | [Solution](walkthrough/challenge-06/solution-06.md) |

## How to use this repo (lab attendee)

1. Read **[Attendee Prerequisites](PREREQUISITES.md)** — 5 minutes, do once.
   It covers sign-in, your `labuser-NN` resource group, and the env-var
   setup every walkthrough assumes.
2. Open **[Challenge 1](challenges/challenge-01.md)**. Try to solve the
   stated mission yourself before peeking.
3. Stuck? Open the matching **[Solution](walkthrough/)** in the
   walkthrough folder — these are full step-by-steps with portal screenshots.
4. Repeat for challenges 2–6.

Raise your hand for a coach any time. The 6 challenges build on each other —
finish them in order.

## Build the environment

A one-shot Bicep + script bootstrap stands up the foundation an attendee
needs to start Challenge 1: an in-country resource group, Premium HSM Key
Vault, RSA-HSM key with rotation policy, GRS storage account encrypted
with that CMK, Log Analytics workspace, and the subscription-scope
Allowed-Locations policy assignments pinned to South Africa regions.

```bash
cd bootstrap
./build-za.sh         # bash / zsh
# or
pwsh ./build-za.ps1   # PowerShell
```

See [`bootstrap/README.md`](bootstrap/README.md) for full details, what
gets deployed, prerequisites, and cleanup.

## Attribution
Based on the [Microsoft Sovereign Cloud MicroHack](https://github.com/microsoft/MicroHack/tree/main/03-Azure/01-03-Infrastructure/01_Sovereign_Cloud)
(MIT-licensed) by Jan Egil Ring, Ye Zhang, Murali Rao Yelamanchili and other
Microsoft contributors. South Africa customizations © Sovereignty Summit ZA
Chapter.
