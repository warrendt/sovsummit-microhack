# Challenge NG-02 — CBN-compliant hybrid landing zone with Azure Local + Arc

> **Country:** ${country.name}
> **Edition:** ${country.summit_edition}
> **Closest Azure region:** `${country.azure.primary_region}` (${country.azure.primary_region_display})

## Scenario

You are the chief architect for **${country.scenarios.financial_tenant}**.
The bank's board and compliance team will approve Azure only if you can prove
that customer financial PII, BVN/KYC records and core transaction data stay on
infrastructure physically located inside Nigeria, while derived analytics can run
in `${country.azure.primary_region}` under documented NDPA and CBN controls.

Design a **two-tier hybrid landing zone**:

- **Regulated tier (inside Nigeria):** Azure Local cluster in a Nigerian data
  centre running the customer profile store, payment APIs, tokenisation
  services, and detokenisation keys, projected into Azure as Arc-enabled
  resources.
- **Derived tier (`${country.azure.primary_region}`):** De-identified analytics,
  model training, SIEM correlation for non-regulated telemetry, and DR copies of
  tokenised data encrypted with CMK in a `${country.azure.cmk_hsm_sku}` Key Vault.

This is the pattern to use when the bank decides that raw customer records,
cryptographic control points and recovery copies must remain in-country. It is
**not** the only Nigeria answer, but it is a valid CBN-first posture.

Regulations in scope:

- **CBN Risk-Based Cybersecurity Framework (2024)** — especially **para. 2.1.5**
  (risk monitoring/reporting), **para. 2.6** (third parties), **para. 5**
  (metrics / monitoring / reporting), **para. 6** (statutory compliance) and
  **para. 7** (enforcement).
- **CBN Shared Services / Outsourcing Guidelines** — board approval, contract,
  audit rights, due diligence, exit/repatriation.
- **NDPA 2023 + GAID 2025** — minimisation, breach handling and cross-border
  transfer controls for derived data.

## Objectives

- Deploy a 2-node **Azure Local** lab cluster (simulated with LocalBox) and
  register it with Azure Arc.
- Onboard at least one workload VM and one AKS-on-Azure-Local cluster as
  Arc-enabled resources in `${country.azure.arc_region}`.
- Build a **CBN Hybrid Landing Zone** policy initiative that:
  - Denies any resource tagged `cbn-tier=regulated` from being created in
    `${country.azure.primary_region}` or any other public Azure region.
  - Requires `encryption.keySource = Microsoft.Keyvault` for all storage in the
    derived tier.
  - Requires `privateEndpointConnections[*]` for storage, SQL and Key Vault in
    the derived tier.
  - Audits Arc-enabled servers missing `ng-datacentre`, `cbn-outsourcing-id`,
    `data-classification`, or `detokenisation-owner` tags.
- Implement a **tokenisation path** where regulated data is tokenised inside
  Nigeria before the derived data set is sent to `${country.azure.primary_region}`.
- Produce an **outsourcing evidence pack** covering cloud-provider due diligence,
  right-to-audit, regulator access, incident notification and exit / repatriation.

## Success criteria

- [ ] `az connectedmachine list -g rg-ng-arc` shows your regulated tier VMs as
      `Connected`.
- [ ] Attempting to create a storage account or VM in
      `${country.azure.primary_region}` with `cbn-tier=regulated` is **denied**.
- [ ] A storage account in the derived tier without a private endpoint is
      rejected or flagged `NonCompliant`.
- [ ] Tokenised data lands in `${country.azure.primary_region}`; reversing the
      token requires the Nigeria-hosted service / key material.
- [ ] A restore drill in `${country.azure.paired_region}` proves the DR copy is
      usable for analytics but not for reconstructing raw PII.
- [ ] Your evidence pack maps controls to the **CBN 2024 Framework**
      (**paras. 2.1.5, 2.6, 5, 6 and 7**), the **CBN Shared Services /
      Outsourcing Guidelines**, and the relevant **NDPA / GAID 2025** controls.

## Guiding questions (try before peeking)

- Which tier owns the detokenisation secret, and how do you prove it never left
  Nigeria?
- If the public-cloud tier is unavailable, what exactly is your regulated-tier
  fallback and how long can it run independently?
- Which artefacts would a CBN examiner request first: the architecture diagram,
  the contract, or the operational evidence? How will you produce all three?
- Can your SOC monitor both Azure Arc and public Azure without accidentally
  sending raw regulated logs outside Nigeria?

## Nigeria-specific pitfalls

- **Arc is a control plane, not a residency waiver:** Arc registration in
  `${country.azure.arc_region}` does not make the regulated workload “public
  cloud”; the compute and data still need to stay in Nigeria.
- **Derived-data sprawl:** once the team sees analytics working in
  `${country.azure.primary_region}`, it may try to move raw operational tables
  there too. Stop this with tags and deny policies.
- **Outsourcing evidence is not optional:** the CBN lens is governance-heavy.
  Keep the board approval, due-diligence memo, audit-rights clause inventory and
  exit plan with the technical evidence.
- **Key custody matters:** if you claim customer-controlled encryption, document
  whether keys are generated in Nigeria, imported, wrapped or rotated, and who
  approves each lifecycle action.

## Control split

| Domain | Nigeria regulated tier | `${country.azure.primary_region}` derived tier |
|---|---|---|
| Raw BVN / KYC / cardholder data | ✅ yes | ❌ no |
| Tokenisation / detokenisation | ✅ yes | ❌ no |
| Derived analytics tables | ❌ no | ✅ yes |
| DR for tokenised datasets | Optional local copy | ✅ yes |
| Key material for public-cloud CMK | Prefer Nigeria source / HSM ceremony | Key operation endpoint only |

## Regulator references

${country.regulatory.regulator_links}

## Stretch goals

- Use a Nigerian HSM ceremony to seed the public-cloud CMK chain for the
  derived tier.
- Add a quarterly attestation that the outsourcing register, inventory and exit
  plan still match production reality.
- Extend the landing zone with a payments-specific zone that isolates switching
  telemetry from general digital-channel analytics.

## Estimated duration
120 minutes.
