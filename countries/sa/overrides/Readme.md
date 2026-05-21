# ${country.summit_edition} — MicroHack

> Saudi Arabia edition of the **Sovereignty Summit MicroHack** for teams building
> public-sector, critical-national-infrastructure, and SAMA-regulated workloads.

## Saudi Arabia at a glance

| Item | Value |
|---|---|
| Country | ${country.name} |
| Primary Azure region | `${country.azure.primary_region}` (${country.azure.primary_region_display}) |
| Exception geo-DR region | `${country.azure.paired_region}` (${country.azure.paired_region_display}) |
| Sovereign-aligned region | `${country.azure.sovereign_region}` |
| Resilience pattern | ${country.azure.availability_architecture} |
| Primary data-protection law | ${country.regulatory.primary_law} |
| PDPL status | ${country.regulatory.enforcement_status} |
| Regulatory stack | ${country.regulatory.frameworks} |
| Confidential compute SKUs | ${country.azure.confidential_compute_skus} |
| Key custody default | `${country.azure.cmk_hsm_sku}` Key Vault / HSM in `${country.azure.primary_region}` |
| Sponsor | ${country.sponsor.primary} |

## What is different in the Saudi edition

- **In-country first:** production data, keys, backups, and operational telemetry
  stay in `${country.azure.primary_region}` by default.
- **Cross-border DR is exceptional:** `${country.azure.paired_region}` is used only
  when there is a documented regulator-approved disaster-recovery exception.
- **Three regulators matter at once:** ${country.regulatory.regulator_split}
- **Two sector stories are emphasized:**
  - **Public sector:** ${country.scenarios.public_sector_tenant}
  - **Financial services:** ${country.scenarios.financial_tenant}

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

- `${country.azure.primary_region}` is the primary production region.
- `${country.azure.paired_region}` is **not** treated as a normal active-active
  secondary; it exists only for approved DR exceptions.
- NCA ECC / CCC define the sovereign landing-zone baseline for government and
  critical workloads.
- SAMA overlays cloud-adoption approval, third-party audit rights, incident
  handling, and exit obligations for regulated banks and payments institutions.

## Regulator references

${country.regulatory.regulator_links}

## Attribution

Based on the [Microsoft Sovereign Cloud MicroHack](https://github.com/microsoft/MicroHack/tree/main/03-Azure/01-03-Infrastructure/01_Sovereign_Cloud)
(MIT-licensed) by Jan Egil Ring, Ye Zhang, Murali Rao Yelamanchili and other
Microsoft contributors. Saudi Arabia customizations © Sovereignty Summit KSA
Chapter.
