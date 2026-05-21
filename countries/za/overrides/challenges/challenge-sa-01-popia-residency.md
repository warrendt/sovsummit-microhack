# Challenge SA-01 — Enforce POPIA data residency with Azure Policy + CMK

> **Country:** ${country.name}
> **Edition:** ${country.summit_edition}
> **Primary region:** `${country.azure.primary_region}` (${country.azure.primary_region_display})
> **Paired region:** `${country.azure.paired_region}` (${country.azure.paired_region_display})

## Scenario

You are the cloud platform engineer for **${country.scenarios.public_sector_tenant}**.
Your CISO has signed off on Azure as the strategic cloud, conditional on
provable enforcement of the following sovereignty controls:

1. All workload resources are deployed **only** in
   `${country.azure.primary_region}` or `${country.azure.paired_region}`.
2. Storage accounts, SQL databases, Cosmos DB and disks are encrypted with
   **customer-managed keys** stored in an HSM-backed Azure Key Vault
   (SKU: `${country.azure.cmk_hsm_sku}`) that lives in
   `${country.azure.primary_region}`.
3. Diagnostic/telemetry data does **not** egress South Africa (no Log Analytics
   workspaces, Application Insights instances or Azure Monitor data exports
   outside the approved regions).
4. Cross-border data transfers under **POPIA s.72** require a documented
   exception; the platform must surface any non-compliant resource within
   24 hours of creation.

Regulatory references in scope: ${country.regulatory.frameworks}.

## Objectives

By the end of this challenge you will have:

- Built a **policy initiative** (`Sovereignty Summit ZA / POPIA Residency`) that
  combines built-in and custom Azure policies to enforce the four controls
  above.
- Assigned the initiative at a **management group** scope with a deny effect
  for region violations and audit/deployIfNotExists for the rest.
- Provisioned a **Premium Key Vault** with purge protection + soft delete in
  `${country.azure.primary_region}` and configured at least one storage account
  to use a CMK from that vault.
- Produced a **compliance evidence pack** (CSV + screenshots) that you could
  hand to the Information Regulator on request.

## Success criteria

- [ ] `az policy state list --management-group <mg>` returns zero
      `NonCompliant` resources for the residency policy after remediation.
- [ ] A test deployment to any region other than
      `${country.azure.primary_region}` / `${country.azure.paired_region}` is
      **denied** at create time.
- [ ] `az keyvault show` confirms `sku.name = ${country.azure.cmk_hsm_sku}`,
      `purgeProtection = true`, `softDelete = true`, and the vault is in
      `${country.azure.primary_region}`.
- [ ] A storage account in the workload RG reports
      `encryption.keySource = Microsoft.Keyvault` against the CMK.
- [ ] Your evidence pack maps each control to a POPIA section
      (1→s.19, 2→s.19+s.20, 3→s.72, 4→s.72/process).

## Hints

- Start from the built-in initiative
  `Allowed locations` (`e56962a6-4747-49cd-b67b-bf8b01975c4c`) and extend with
  `Allowed locations for resource groups`.
- For the CMK requirement, combine
  `Storage accounts should use customer-managed key for encryption`
  (deployIfNotExists) with
  `Azure Key Vault should use RBAC permission model`.
- Diagnostic-data residency can be enforced via
  `Configure Azure Activity logs to stream to specified Log Analytics workspace`
  pinned to a workspace in `${country.azure.primary_region}`.

## Regulator references

${country.regulatory.regulator_links}

## Estimated duration
60 minutes.
