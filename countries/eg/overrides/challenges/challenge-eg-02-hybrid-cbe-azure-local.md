# Challenge EG-02 — Hybrid CBE-compliant landing zone with Azure Local + Arc

> **Country:** ${country.name}
> **Edition:** ${country.summit_edition}
> **Closest Azure region:** `${country.azure.primary_region}` (${country.azure.primary_region_display})

## Scenario

You are the chief architect for **${country.scenarios.financial_tenant}**.
CBE has approved your cloud strategy on one condition: **all customer
financial PII and core banking data must reside on infrastructure physically
located inside Egypt**. Non-PII analytics and DR replicas may run in
`${country.azure.primary_region}` under a PDPC cross-border permit.

You will build a **two-tier hybrid landing zone**:

- **Regulated tier (on-prem in Cairo / Alexandria):** Azure Local (formerly
  Azure Stack HCI) cluster running the wallet-issuance services and customer
  database. Projected to Azure as Arc-enabled resources.
- **Non-regulated tier (`${country.azure.primary_region}`):** Tokenised
  analytics warehouse, model training, and DR copies of de-identified data
  protected by CMK in a **${country.azure.cmk_hsm_sku}** Key Vault.

## Objectives

- Deploy a 2-node **Azure Local** cluster (simulated; use the
  `common/resources/demo-vm-creator/deploy-localbox.ps1` LocalBox to stand up
  a nested-virtualised lab) and register it with Azure Arc.
- Onboard at least one workload VM and one AKS-on-Azure-Local cluster as
  Arc-enabled resources; verify they appear in the `${country.azure.arc_region}`
  resource group.
- Build a **CMK pipeline**: tokeniser running on the on-prem cluster strips
  customer PII before pushing to a storage account in
  `${country.azure.primary_region}` whose encryption key lives in a
  Premium Key Vault, with the **wrapping key** never leaving Egypt
  (Managed HSM exported via BYOK or held in an on-prem HSM).
- Apply an **Azure Policy** initiative `CBE Hybrid Landing Zone` that:
  - Denies storage accounts in the regulated subscription unless `encryption.keySource = Microsoft.Keyvault`.
  - Denies any compute resource not tagged `cbe-tier=regulated` from being deployed in `${country.azure.primary_region}`.
  - Audits Arc-enabled servers missing the `azure-arc-eg-data-centre` tag.
- Wire **Azure Monitor** to a Log Analytics workspace in
  `${country.azure.primary_region}` (allowed under CBE for non-regulated
  telemetry) **plus** a local Arc-enabled MMA → on-prem SIEM for regulated
  telemetry.

## Success criteria

- [ ] `az connectedmachine list -g rg-eg-arc` shows at least the regulated
      tier VMs as `Connected`.
- [ ] Attempting `az storage account create -l ${country.azure.primary_region}` with the
      `cbe-tier=regulated` tag is **denied** by policy.
- [ ] Customer PII written via the tokeniser appears in
      `${country.azure.primary_region}` storage as tokens only; reversing
      requires the on-prem HSM (demonstrate by deliberately blocking egress).
- [ ] DR replica restore drill: spin up a temporary VM in
      `${country.azure.paired_region}` from a tokenised backup and verify it
      cannot resolve the original PII.
- [ ] Compliance evidence pack maps each control back to CBE Cloud Computing
      Framework sections + PDPL Article numbers.

## Hints

- Start from `common/resources/demo-vm-creator/deploy-localbox.ps1` (set
  `-AzureLocalInstanceLocation ${country.azure.azure_local_instance_location}` so the
  registration plane lives near the lab).
- For tokenisation, an open-source option such as `Microsoft Presidio`
  running on the on-prem AKS cluster is sufficient for the lab.
- The `Azure Arc-enabled data services` policy initiative is a useful
  baseline to extend.
- Reference: ${country.regulatory.regulator_links}.

## Estimated duration
120 minutes.
