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

1. Azure native sovereign controls (Policy, RBAC) — see [`challenges/challenge-01.md`](challenges/challenge-01.md)
2. Encryption at rest with CMK — [`challenges/challenge-02.md`](challenges/challenge-02.md)
3. Encryption in transit (TLS) — [`challenges/challenge-03.md`](challenges/challenge-03.md)
4. Confidential VMs — [`challenges/challenge-04.md`](challenges/challenge-04.md)
5. Confidential AKS — [`challenges/challenge-05.md`](challenges/challenge-05.md)
6. Azure Local + Arc — [`challenges/challenge-06.md`](challenges/challenge-06.md)

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
