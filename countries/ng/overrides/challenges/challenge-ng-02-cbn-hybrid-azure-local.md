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
  centre running the customer profile store, payment APIs and tokenisation
  services, projected into Azure as Arc-enabled resources.
- **Derived tier (`${country.azure.primary_region}`):** De-identified analytics,
  model training, SIEM correlation for non-regulated telemetry, and DR copies of
  tokenised data encrypted with CMK in a `${country.azure.cmk_hsm_sku}` Key Vault.

Regulations in scope:

- **CBN Risk-Based Cybersecurity Framework (2024)** — especially **para. 2.1.5**
  (risk monitoring/reporting), **para. 2.6** (third parties), **para. 5**
  (metrics / monitoring / reporting), **para. 6** (statutory compliance) and
  **para. 7** (enforcement).
- **CBN Shared Services / Outsourcing Guidelines** — board approval, contract,
  audit rights, due diligence, exit/repatriation.
- **NDPA 2023 / NDPR 2019** — personal-data minimisation, breach handling and
  cross-border transfer controls for derived data.

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
  - Audits Arc-enabled servers missing `ng-datacentre`, `cbn-outsourcing-id`,
    or `data-classification` tags.
- Implement a **tokenisation path** where regulated data is tokenised inside
  Nigeria before the derived data set is sent to `${country.azure.primary_region}`.
- Produce an **outsourcing evidence pack** covering cloud-provider due diligence,
  right-to-audit, regulator access, incident notification and exit / repatriation.

## Success criteria

- [ ] `az connectedmachine list -g rg-ng-arc` shows your regulated tier VMs as
      `Connected`.
- [ ] Attempting to create a storage account or VM in
      `${country.azure.primary_region}` with `cbn-tier=regulated` is **denied**.
- [ ] Tokenised data lands in `${country.azure.primary_region}`; reversing the
      token requires the Nigeria-hosted service / key material.
- [ ] A restore drill in `${country.azure.paired_region}` proves the DR copy is
      usable for analytics but not for reconstructing raw PII.
- [ ] Your evidence pack maps controls to the **CBN 2024 Framework**
      (**paras. 2.1.5, 2.6, 5, 6 and 7**) and the **CBN Shared Services /
      Outsourcing Guidelines**.

## Hints

- Start from `common/resources/demo-vm-creator/deploy-localbox.ps1` and keep the
  Arc registration plane in `${country.azure.azure_local_instance_location}`.
- Use `cbn-tier=regulated` and `cbn-tier=derived` as the primary split tag.
- For tokenisation, an on-prem service such as **Microsoft Presidio** is fine
  for the lab if the detokenisation secrets never leave Nigeria.
- The **CBN Risk-Based Cybersecurity Framework** expects strong third-party due
  diligence and ongoing monitoring; treat Azure as a controlled outsourcing
  relationship, not just a destination region.
- Reference: ${country.regulatory.regulator_links}.

## Estimated duration
120 minutes.
