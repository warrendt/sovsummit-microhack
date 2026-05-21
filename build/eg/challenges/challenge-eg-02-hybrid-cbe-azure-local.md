# Challenge EG-02 — Hybrid CBE-compliant landing zone with Azure Local + Arc

> **Country:** Egypt
> **Edition:** Sovereignty Summit Egypt 2026
> **Closest Azure region:** `uaenorth` (UAE North (closest hyperscale region to Egypt))

## Scenario

You are the chief architect for **An Egyptian tier-1 bank operating mobile wallets under CBE cloud rules**.
CBE has approved your cloud strategy on one condition: **all customer
financial PII and core banking data must reside on infrastructure physically
located inside Egypt**. Non-PII analytics and DR replicas may run in
`uaenorth` under a PDPC cross-border permit.

You will build a **two-tier hybrid landing zone**:

- **Regulated tier (on-prem in Cairo / Alexandria):** Azure Local (formerly
  Azure Stack HCI) cluster running the wallet-issuance services and customer
  database. Projected to Azure as Arc-enabled resources.
- **Non-regulated tier (`uaenorth`):** Tokenised
  analytics warehouse, model training, and DR copies of de-identified data
  protected by CMK in a **Premium** Key Vault.

## Objectives

- Deploy a 2-node **Azure Local** cluster (simulated; use the
  `common/resources/demo-vm-creator/deploy-localbox.ps1` LocalBox to stand up
  a nested-virtualised lab) and register it with Azure Arc.
- Onboard at least one workload VM and one AKS-on-Azure-Local cluster as
  Arc-enabled resources; verify they appear in the `uaenorth`
  resource group.
- Build a **CMK pipeline**: tokeniser running on the on-prem cluster strips
  customer PII before pushing to a storage account in
  `uaenorth` whose encryption key lives in a
  Premium Key Vault, with the **wrapping key** never leaving Egypt
  (Managed HSM exported via BYOK or held in an on-prem HSM).
- Apply an **Azure Policy** initiative `CBE Hybrid Landing Zone` that:
  - Denies storage accounts in the regulated subscription unless `encryption.keySource = Microsoft.Keyvault`.
  - Denies any compute resource not tagged `cbe-tier=regulated` from being deployed in `uaenorth`.
  - Audits Arc-enabled servers missing the `azure-arc-eg-data-centre` tag.
- Wire **Azure Monitor** to a Log Analytics workspace in
  `uaenorth` (allowed under CBE for non-regulated
  telemetry) **plus** a local Arc-enabled MMA → on-prem SIEM for regulated
  telemetry.

## Success criteria

- [ ] `az connectedmachine list -g rg-eg-arc` shows at least the regulated
      tier VMs as `Connected`.
- [ ] Attempting `az storage account create -l uaenorth` with the
      `cbe-tier=regulated` tag is **denied** by policy.
- [ ] Customer PII written via the tokeniser appears in
      `uaenorth` storage as tokens only; reversing
      requires the on-prem HSM (demonstrate by deliberately blocking egress).
- [ ] DR replica restore drill: spin up a temporary VM in
      `uaecentral` from a tokenised backup and verify it
      cannot resolve the original PII.
- [ ] Compliance evidence pack maps each control back to CBE Cloud Computing
      Framework sections + PDPL Article numbers.

## Hints

- Start from `common/resources/demo-vm-creator/deploy-localbox.ps1` (set
  `-AzureLocalInstanceLocation uaenorth` so the
  registration plane lives near the lab).
- For tokenisation, an open-source option such as `Microsoft Presidio`
  running on the on-prem AKS cluster is sufficient for the lab.
- The `Azure Arc-enabled data services` policy initiative is a useful
  baseline to extend.
- Reference: {'name': 'Personal Data Protection Center (PDPC)', 'url': 'https://pdpc.gov.eg/'}, {'name': 'Central Bank of Egypt', 'url': 'https://www.cbe.org.eg/'}, {'name': 'National Telecommunications Regulatory Authority (NTRA)', 'url': 'https://www.tra.gov.eg/'}.

## Estimated duration
120 minutes.
