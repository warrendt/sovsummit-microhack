# Challenge NG-02 — CBN-compliant hybrid landing zone with Azure Local + Arc

> **Country:** Nigeria
> **Edition:** Sovereignty Summit Nigeria 2026
> **Closest Azure region:** `southafricanorth` (South Africa North (closest hyperscale region to Nigeria))

## Scenario

You are the chief architect for **A tier-1 Nigerian bank modernising digital channels under CBN cloud and outsourcing rules**.
The bank's board and compliance team will approve Azure only if you can prove
that customer financial PII, BVN/KYC records and core transaction data stay on
infrastructure physically located inside Nigeria, while derived analytics can run
in `southafricanorth` under documented NDPA and CBN controls.

Design a **two-tier hybrid landing zone**:

- **Regulated tier (inside Nigeria):** Azure Local cluster in a Nigerian data
  centre running the customer profile store, payment APIs and tokenisation
  services, projected into Azure as Arc-enabled resources.
- **Derived tier (`southafricanorth`):** De-identified analytics,
  model training, SIEM correlation for non-regulated telemetry, and DR copies of
  tokenised data encrypted with CMK in a `Premium` Key Vault.

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
  Arc-enabled resources in `southafricanorth`.
- Build a **CBN Hybrid Landing Zone** policy initiative that:
  - Denies any resource tagged `cbn-tier=regulated` from being created in
    `southafricanorth` or any other public Azure region.
  - Requires `encryption.keySource = Microsoft.Keyvault` for all storage in the
    derived tier.
  - Audits Arc-enabled servers missing `ng-datacentre`, `cbn-outsourcing-id`,
    or `data-classification` tags.
- Implement a **tokenisation path** where regulated data is tokenised inside
  Nigeria before the derived data set is sent to `southafricanorth`.
- Produce an **outsourcing evidence pack** covering cloud-provider due diligence,
  right-to-audit, regulator access, incident notification and exit / repatriation.

## Success criteria

- [ ] `az connectedmachine list -g rg-ng-arc` shows your regulated tier VMs as
      `Connected`.
- [ ] Attempting to create a storage account or VM in
      `southafricanorth` with `cbn-tier=regulated` is **denied**.
- [ ] Tokenised data lands in `southafricanorth`; reversing the
      token requires the Nigeria-hosted service / key material.
- [ ] A restore drill in `southafricawest` proves the DR copy is
      usable for analytics but not for reconstructing raw PII.
- [ ] Your evidence pack maps controls to the **CBN 2024 Framework**
      (**paras. 2.1.5, 2.6, 5, 6 and 7**) and the **CBN Shared Services /
      Outsourcing Guidelines**.

## Hints

- Start from `common/resources/demo-vm-creator/deploy-localbox.ps1` and keep the
  Arc registration plane in `southafricanorth`.
- Use `cbn-tier=regulated` and `cbn-tier=derived` as the primary split tag.
- For tokenisation, an on-prem service such as **Microsoft Presidio** is fine
  for the lab if the detokenisation secrets never leave Nigeria.
- The **CBN Risk-Based Cybersecurity Framework** expects strong third-party due
  diligence and ongoing monitoring; treat Azure as a controlled outsourcing
  relationship, not just a destination region.
- Reference: {'name': 'Nigeria Data Protection Commission', 'url': 'https://ndpc.gov.ng/'}, {'name': 'Central Bank of Nigeria', 'url': 'https://www.cbn.gov.ng/'}, {'name': 'National Information Technology Development Agency (NITDA)', 'url': 'https://www.nitda.gov.ng/'}.

## Estimated duration
120 minutes.
