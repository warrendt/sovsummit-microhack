# ${country.summit_edition} — MicroHack

> Country edition of the **Sovereignty Summit MicroHack** for **${country.name}**.
> Generated from `common/` + `countries/${country.iso2}/overrides/` via
> `tools/render.py`.

## Country context

| Item | Value |
|---|---|
| Country | ${country.name} |
| Primary Azure region | `${country.azure.primary_region}` (${country.azure.primary_region_display}) |
| Paired Azure region | `${country.azure.paired_region}` (${country.azure.paired_region_display}) |
| Primary data-protection law | ${country.regulatory.primary_law} |
| Regulatory frameworks in scope | ${country.regulatory.frameworks} |
| Confidential compute SKUs | ${country.azure.confidential_compute_skus} |
| Key Vault SKU | ${country.azure.cmk_hsm_sku} |
| Sponsor | ${country.sponsor.primary} |

### Scenarios used throughout the challenges
- **Public sector:** ${country.scenarios.public_sector_tenant}
- **Financial services:** ${country.scenarios.financial_tenant}

### South Africa–specific notes
- All workload data (including backups and diagnostic data) must remain inside
  South Africa unless an explicit cross-border transfer assessment has been
  performed under **POPIA s.72**.
- Financial-sector workloads are additionally governed by **SARB Directive
  3/2018** on cloud computing and the offshoring of data.
- Customer-managed keys live in a **Premium Key Vault** (HSM-backed) in
  `${country.azure.primary_region}` with geo-replication to
  `${country.azure.paired_region}`.

## Challenges

In this country edition the following challenges run in order:

1. Azure native sovereign controls (Policy, RBAC) — see [`challenges/challenge-01.md`](challenges/challenge-01.md)
2. Encryption at rest with CMK — [`challenges/challenge-02.md`](challenges/challenge-02.md)
3. Encryption in transit (TLS) — [`challenges/challenge-03.md`](challenges/challenge-03.md)
4. Confidential VMs — [`challenges/challenge-04.md`](challenges/challenge-04.md)
5. Confidential AKS — [`challenges/challenge-05.md`](challenges/challenge-05.md)
6. Azure Local + Arc — [`challenges/challenge-06.md`](challenges/challenge-06.md)
7. **🇿🇦 POPIA data-residency enforcement** — [`challenges/challenge-sa-01-popia-residency.md`](challenges/challenge-sa-01-popia-residency.md)

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
