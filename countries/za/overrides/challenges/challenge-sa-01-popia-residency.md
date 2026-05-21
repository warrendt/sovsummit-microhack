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

## Guiding questions (try before peeking)

- A built-in `Allowed locations` policy denies *resources*; what does it
  fail to deny, and which companion policy must you also assign?
- "Deny at create time" vs "audit + remediate later" — which one would
  you defend to the Information Regulator after a cross-border leak?
- Diagnostic settings can quietly route data out of the country if a
  developer picks a Log Analytics workspace in `westeurope`. How do you
  *prevent* that, not just *detect* it?
- POPIA s.72 allows cross-border transfers in defined circumstances. How
  would you build an **exemption workflow** that documents the legal
  basis whenever an exception is granted?

## ${country.name}-specific pitfalls

- **`${country.azure.cmk_hsm_sku}` Key Vault availability** in
  `${country.azure.primary_region}` is reliable but verify before the
  workshop — Managed HSM is **not** in every South African region.
- **Activity logs vs resource logs:** activity logs are a tenant-level
  setting and route to subscription-level diagnostic settings —
  pinning the workspace there protects *everything*, not just one
  resource type.
- **Geo-redundant storage** in `${country.azure.primary_region}`
  replicates to `${country.azure.paired_region}`. Both are inside South
  Africa, but make sure your `Allowed locations` initiative explicitly
  includes the paired region or your GRS deployments will fail policy.
- **Tag remediation** requires a managed identity on the policy
  assignment — without it `modify`-effect policies report
  "Non-compliant" forever.

## Deeper POPIA mapping

| Control                              | POPIA section(s) |
|--------------------------------------|------------------|
| Region restriction                   | s.72             |
| HSM-backed CMK + key custody         | s.19, s.20       |
| Record of processing activities      | s.14             |
| Notification of security compromise  | s.22             |
| Special personal information         | s.26             |
| Information Officer responsibilities | s.55             |

Each entry in your evidence pack should reference at least one row.

## Regulator references

${country.regulatory.regulator_links}

## Stretch goals

- Publish the initiative as Bicep under source control with a CI check
  that fails the build if anyone weakens a `deny` effect to `audit`.
- Build a Logic App that emails the Information Officer whenever an
  exemption is granted under POPIA s.72.
- Extend the evidence pack with a quarterly attestation template the
  Accounting Officer can sign and return to the Information Regulator.
- Repeat the entire challenge for the financial-services scenario
  (${country.scenarios.financial_tenant}) and add the SARB Directive
  3/2018 mapping next to the POPIA one.
