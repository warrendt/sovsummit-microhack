# ${country.summit_edition} — MicroHack

> Country edition of the **Sovereignty Summit MicroHack** for **${country.name}**.
> Generated from `common/` + `countries/${country.iso2}/overrides/` via
> `tools/render.py`.

## Saudi Arabia context

| Item | Value |
|---|---|
| Country | ${country.name} |
| Primary Azure region | `${country.azure.primary_region}` (${country.azure.primary_region_display}) |
| Paired region used in this edition | `${country.azure.paired_region}` (${country.azure.paired_region_display}) |
| Sovereign-aligned region | `${country.azure.sovereign_region}` |
| Resilience pattern | ${country.azure.availability_architecture} |
| Primary data-protection law | ${country.regulatory.primary_law} |
| PDPL status | ${country.regulatory.enforcement_status} |
| Regulator split | ${country.regulatory.regulator_split} |
| Regulatory frameworks in scope | ${country.regulatory.frameworks} |
| Confidential compute SKUs | ${country.azure.confidential_compute_skus} |
| Key Vault SKU | ${country.azure.cmk_hsm_sku} |
| Sponsor | ${country.sponsor.primary} |

### Scenarios used throughout the challenges
- **Public sector:** ${country.scenarios.public_sector_tenant}
- **Financial services:** ${country.scenarios.financial_tenant}

### Saudi-specific notes
- Microsoft publicly positions **${country.azure.primary_region_display}** as the
  in-country Azure region for Saudi data residency, low latency, and
  sovereign-ready cloud adoption aligned to Vision 2030.
- The public Azure regions list does **not** yet show a formal region pair for
  `${country.azure.primary_region}`. For this edition we use
  **${country.azure.paired_region_display}** as the most plausible geo-DR target
  because it is the nearest mature Gulf region that still keeps recovery inside
  the wider GCC neighbourhood. Treat this as a **design assumption**, not an
  official Microsoft pairing.
- Default resilience for regulated workloads should stay **inside the Kingdom**:
  use the three availability zones in `${country.azure.primary_region}` first,
  and only replicate to `${country.azure.paired_region}` after a documented
  ${country.regulatory.cross_border_transfer_model}
- ${country.regulatory.regulator_split}
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
