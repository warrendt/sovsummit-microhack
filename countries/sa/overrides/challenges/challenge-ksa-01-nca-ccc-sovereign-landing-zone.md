# Challenge KSA-01 — NCA CCC-aligned sovereign landing zone with Microsoft Cloud for Sovereignty + CMK

> **Country:** ${country.name}
> **Edition:** ${country.summit_edition}
> **Primary region:** `${country.azure.primary_region}` (${country.azure.primary_region_display})
> **Planned geo-DR target for this edition:** `${country.azure.paired_region}` (${country.azure.paired_region_display})

## Scenario

You are the platform lead for **${country.scenarios.public_sector_tenant}**.
Your architecture review board has approved Azure on three conditions:

1. The landing zone must align to **NCA Cloud Cybersecurity Controls
   (CCC-1:2020)** and inherit baseline controls from **ECC-1:2018** and
   **CSCC-1:2019**.
2. All production data, keys, and operational logs must stay in
   `${country.azure.primary_region}` unless there is a formally approved
   disaster-recovery exception.
3. The platform team must use **Microsoft Cloud for Sovereignty** patterns
   (policy-driven landing zones, tenant isolation, auditability, and data
   boundary controls) to prove compliance to both security and privacy teams.

Regulatory context in scope: ${country.regulatory.frameworks}.

## Objectives

By the end of this challenge you will have:

- Built a **sovereign landing-zone hierarchy** for KSA with separate
  `platform`, `workloads`, and `dr-exception` scopes.
- Created an **NCA CCC initiative** that enforces:
  - Allowed locations (`${country.azure.primary_region}` by default).
  - CMK for storage, SQL, and managed disks with keys held in a
    `${country.azure.cmk_hsm_sku}` Key Vault in `${country.azure.primary_region}`.
  - Diagnostic settings to a Log Analytics workspace in
    `${country.azure.primary_region}`.
  - Mandatory tags: `ksa-data-classification`, `ksa-regulator`, and
    `ksa-dr-approved`.
- Applied the initiative at a **management-group** scope with deny effects for
  region drift and audit/deployIfNotExists for CMK and logging.
- Documented the **DR exception path** for `${country.azure.paired_region}` so
  only specifically approved recovery resources can exist outside the Kingdom.
- Produced a **control map** from each Azure guardrail to NCA CCC / ECC control
  families plus the relevant PDPL obligations.

## Success criteria

- [ ] `az policy state list --management-group <mg>` returns zero
      `NonCompliant` resources for the KSA sovereign initiative after
      remediation.
- [ ] A test resource deployment to `uaenorth` or `westeurope` is **denied** at
      create time.
- [ ] `az keyvault show` confirms the vault is in
      `${country.azure.primary_region}`, uses `${country.azure.cmk_hsm_sku}`,
      and has soft delete + purge protection enabled.
- [ ] Log Analytics, Activity Logs, and resource diagnostics land only in
      `${country.azure.primary_region}`.
- [ ] Any resource allowed into `${country.azure.paired_region}` is tagged
      `ksa-dr-approved=true` and is explained in your DR exception register.

## Hints

- Start from the Azure landing-zone pattern and extend it with **Microsoft Cloud
  for Sovereignty** control objectives: policy inheritance, stronger logging,
  identity separation, and evidence collection.
- Built-in policies to combine: **Allowed locations**, **Allowed locations for
  resource groups**, **Storage accounts should use customer-managed key for
  encryption**, **Key vaults should have purge protection enabled**, and
  **Deploy diagnostic settings to Log Analytics workspace**.
- Keep the **workspace, key vault, and policy remediation identity** in
  `${country.azure.primary_region}`.
- Default DR posture is **zones first**. Any cross-border copy to
  `${country.azure.paired_region}` must be justified under
  ${country.regulatory.cross_border_transfer_model}

## Estimated duration
90 minutes.
